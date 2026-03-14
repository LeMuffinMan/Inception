#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

COMPOSE="docker compose -f ${COMPOSE_FILE}"

header "Volume Check" "login: ${LOGIN}"

# =============================================================================
# VOLUME INTEGRITY
# =============================================================================
section "Volume Integrity"

for VOL in "${VOLUMES_TO_CHECK[@]}"; do
    SERVICE="srcs_${VOL}_data"

    if ! docker volume ls | grep -q "$SERVICE"; then
        check "$VOL → volume exists" "ko" "$SERVICE not found"
        continue
    fi

    DRIVER=$(docker volume inspect "$SERVICE" --format '{{.Driver}}')
    DEVICE=$(docker volume inspect "$SERVICE" --format '{{.Options.device}}')
    MOUNTPOINT=$(docker volume inspect "$SERVICE" --format '{{.Mountpoint}}')

    if [ "$DRIVER" = "local" ]; then
        check "$VOL → named volume (local driver)" "ok"
    else
        check "$VOL → named volume (local driver)" "ko" "driver is $DRIVER"
    fi

    if grep -A5 "volumes:" "$COMPOSE_FILE" | grep -qE "\./|/home"; then
        check "$VOL → no bind mount in compose" "ko" "bind mount detected"
    else
        check "$VOL → no bind mount in compose" "ok"
    fi

    if echo "$DEVICE" | grep -qE "$VOLUME_HOST_PATH_PATTERN"; then
        check "$VOL → host path valid" "ok" "$DEVICE"
    else
        check "$VOL → host path valid" "ko" "expected pattern $VOLUME_HOST_PATH_PATTERN, got: $DEVICE"
    fi
done


# =============================================================================
# PERSISTENCE TEST
# =============================================================================
section "Persistence Test"

echo -e "  ${GRAY}→ Running: docker compose down ...${NC}"
$COMPOSE down > /dev/null 2>&1

RUNNING=$($COMPOSE ps -q | wc -l)
if [ "$RUNNING" -eq 0 ]; then
    check "containers stopped" "ok"
else
    check "containers stopped" "ko" "$RUNNING container(s) still running"
fi

ALL_PRESENT=true
for VOL in "${VOLUMES_TO_CHECK[@]}"; do
    SERVICE="srcs_${VOL}_data"
    if docker volume ls | grep -q "$SERVICE"; then
        check "$VOL → volume persists after stop" "ok"
    else
        check "$VOL → volume persists after stop" "ko" "$SERVICE disappeared"
        ALL_PRESENT=false
    fi
done


# =============================================================================
# RESTART & HEALTHCHECK
# =============================================================================
section "Restart & Healthcheck"

echo -e "  ${GRAY}→ Running: docker compose up -d --build --no-recreate ...${NC}"
$COMPOSE up -d --build --no-recreate > /dev/null 2>&1

if [ $? -eq 0 ]; then
    check "containers restarted" "ok"
else
    check "containers restarted" "ko" "docker compose up failed"
    exit 1
fi

echo -e "  ${GRAY}→ Waiting up to ${WAIT_TIMEOUT}s for healthchecks ...${NC}"
ELAPSED=0
ALL_HEALTHY=false
CONTAINER_IDS=$($COMPOSE ps -q)

while [ $ELAPSED -lt $WAIT_TIMEOUT ]; do
    ALL_HEALTHY=true
    for C in $CONTAINER_IDS; do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$C" 2>/dev/null || echo "nohealth")
        if [ "$STATUS" != "healthy" ]; then
            ALL_HEALTHY=false
            break
        fi
    done
    $ALL_HEALTHY && break
    sleep 1
    (( ELAPSED++ ))
done

if $ALL_HEALTHY; then
    check "all containers healthy" "ok" "after ${ELAPSED}s"
else
    check "all containers healthy" "ko" "timed out after ${WAIT_TIMEOUT}s"
fi
