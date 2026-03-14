#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -en "${YELLOW}Stopping containers: ${NC}"

docker compose -f srcs/docker-compose.yml down > /dev/null 2>&1

if [ $(docker compose -f srcs/docker-compose.yml ps -q | wc -l) -eq 0 ]; then
    echo -e "${GREEN}OK${NC}: All containers stopped"
else
    echo -e "${RED}KO${NC}: Some containers are still running"
fi

echo -en "${YELLOW}Volumes persistancy: "
if [ $(docker compose -f srcs/docker-compose.yml ps -q | wc -l) -eq 0 ]; then
    VOLUMES=$(docker volume ls --format "{{.Name}}")
    MDB_VOL=$(echo "$VOLUMES" | grep -w "srcs_mariadb_data")
    WP_VOL=$(echo "$VOLUMES" | grep -w "srcs_wordpress_data")

    if [ -n "$MDB_VOL" ] && [ -n "$WP_VOL" ]; then
        echo -e "${GREEN}OK${NC}: Both volumes still exist: "
        docker volume ls | grep -v "DRIVER"
    else
        echo -e "${RED}KO${NC}: Missing one or both volumes"
    fi
else
    echo -e "${RED}KO${NC}: not all containers are stopped"
fi

echo -en "${YELLOW}Restarting containers: ${NC}"

docker compose -f srcs/docker-compose.yml up -d --build --no-recreate > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}OK${NC}: Containers restarted"
    echo -en "${YELLOW}Waiting for healthchecks: "

    TIMEOUT=30
    ELAPSED=0
    INTERVAL=1

    CONTAINERS=$(docker compose -f srcs/docker-compose.yml ps -q)
    while [ $ELAPSED -lt $TIMEOUT ]; do
        ALL_HEALTHY=true
        for C in $CONTAINERS; do
            STATUS=$(docker inspect --format='{{.State.Health.Status}}' $C 2>/dev/null || echo "nohealth")
            if [ "$STATUS" != "healthy" ]; then
                ALL_HEALTHY=false
                break
            fi
        done

        if [ "$ALL_HEALTHY" = true ]; then
            echo -e "${GREEN}OK${NC}: All containers are healthy${NC}"
            break
        fi

        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

    if [ "$ALL_HEALTHY" = false ]; then
        echo -e "${RED}KO${NC}: Containers not healthy after $TIMEOUT seconds"
    fi
else
    echo -e "${RED}KO${NC}: Failed to restart containers"
fi
