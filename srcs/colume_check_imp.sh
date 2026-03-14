#!/bin/bash

# =============================================================================
# CONFIGURATION
# =============================================================================

LOGIN="oelleaum"

COMPOSE_FILE="$(dirname "$0")/../srcs/docker-compose.yml"

# Volumes to check (will be prefixed with "srcs_" and suffixed with "_data")
VOLUMES_TO_CHECK=("mariadb" "wordpress")

# Expected host path pattern for volumes (must match /home/<login>/data)
VOLUME_HOST_PATH_PATTERN="/home/.*/data"

# How long to wait for containers to become healthy after restart (seconds)
WAIT_TIMEOUT=30

# =============================================================================
# END OF CONFIGURATION
# =============================================================================

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

    # Named volume with local driver
    if [ "$DRIVER" = "local" ]; then
        check "$VOL → named volume (local driver)" "ok"
    else
        check "$VOL → named volume (local driver)" "ko" "driver is $DRIVER"
    fi

    # No bind mount in compose
    if grep -A5 "volumes:" "$COMPOSE_FILE" | grep -qE "\./|/home"; then
        check "$VOL → no bind mount in compose" "ko" "bind mount detected"
    else
        check "$VOL → no bind mount in compose" "ok"
    fi

    # Host path must be under /home/<login>/data
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

# Stop containers
echo -e "  ${GRAY}→ Running: docker compose down ...${NC}"
$COMPOSE down > /dev/null 2>&1

RUNNING=$($COMPOSE ps -q | wc -l)
if [ "$RUNNING" -eq 0 ]; then
    check "containers stopped" "ok"
else
    check "containers stopped" "ko" "$RUNNING container(s) still running"
fi

# Volumes must survive the stop
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

# Wait for all containers to be healthy
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

echo
echo -e "${GRAY}  Done.${NC}"
echo
