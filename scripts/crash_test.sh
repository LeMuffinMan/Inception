#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

COMPOSE="docker compose -f ${COMPOSE_FILE}"

header "Crash Test" "login: ${LOGIN}"

section "Crash Test"

crash_test() {
    local name="$1"
    local CONTAINERS
    CONTAINERS=$($COMPOSE ps)

    if ! echo "$CONTAINERS" | grep -q "$name"; then
        check "$name → container found" "ko" "no $name container running"
        return
    fi
    check "$name → container found" "ok"

    local PID
    PID=$(docker inspect --format '{{.State.Pid}}' "$name" 2>/dev/null)
    echo -e "  ${GRAY}→ sudo kill -9 $PID (pid of $name)${NC}"

    if ! sudo kill -9 "$PID" 2>/dev/null; then
        check "$name → crash triggered" "ko" "kill -9 $PID failed"
        return
    fi
    check "$name → crash triggered" "ok" "pid $PID killed"

    sleep 1

    CONTAINERS=$($COMPOSE ps)
    if ! echo "$CONTAINERS" | grep -q "$name"; then
        check "$name → restarted" "ko" "container did not come back"
        return
    fi

    if echo "$CONTAINERS" | grep "$name" | grep -q "health"; then
        local attempts=0
        while [ $attempts -lt $RESTART_TIMEOUT ]; do
            CONTAINERS=$($COMPOSE ps)
            if echo "$CONTAINERS" | grep "$name" | grep -q "healthy"; then
                break
            fi
            sleep 1
            (( attempts++ ))
        done

        if echo "$CONTAINERS" | grep "$name" | grep -q "healthy"; then
            check "$name → restarted & healthy" "ok" "after ${attempts}s"
        else
            check "$name → restarted & healthy" "ko" "timed out after ${RESTART_TIMEOUT}s"
        fi
    else
        check "$name → restarted" "ok"
    fi
}

crash_all() {
    section "Crash All Containers"

    local PIDS=()
    local NAMES=()
    for CONTAINER in "${CONTAINERS_TO_TEST[@]}"; do
        local PID
        PID=$(docker inspect --format '{{.State.Pid}}' "$CONTAINER" 2>/dev/null)
        if [ -n "$PID" ] && [ "$PID" != "0" ]; then
            PIDS+=("$PID")
            NAMES+=("$CONTAINER")
        else
            check "$CONTAINER → pid found" "ko"
        fi
    done

    echo -e "  ${GRAY}→ sudo kill -9 ${PIDS[*]}${NC}"
    sudo kill -9 "${PIDS[@]}" 2>/dev/null
    check "all containers → crash triggered" "ok" "${#PIDS[@]} processes killed"

    sleep 1

    for CONTAINER in "${NAMES[@]}"; do
        local attempts=0
        while [ $attempts -lt $RESTART_TIMEOUT ]; do
            CONTAINERS=$($COMPOSE ps)
            if echo "$CONTAINERS" | grep "$CONTAINER" | grep -q "healthy"; then
                break
            fi
            sleep 1
            (( attempts++ ))
        done

        if echo "$CONTAINERS" | grep "$CONTAINER" | grep -q "healthy"; then
            check "$CONTAINER → restarted & healthy" "ok" "after ${attempts}s"
        else
            check "$CONTAINER → restarted & healthy" "ko" "timed out after ${RESTART_TIMEOUT}s"
        fi
    done
}

for CONTAINER in "${CONTAINERS_TO_TEST[@]}"; do
    crash_test "$CONTAINER"
done

crash_all
