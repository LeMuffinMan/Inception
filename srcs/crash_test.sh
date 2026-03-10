#!/bin/bash

crash_test() {
    TIMEOUT=30
    if echo "$CONTAINERS" | grep "$1" > /dev/null; then
    echo -en "${YELLOW}Simulating crash on $1: ${NC}docker exec -it $1 ash -c \"kill 1\"${NC}: "
    if docker exec -it $1 ash -c "kill 1"; then
        sleep 1
        CONTAINERS=$($COMPOSE ps)
        if ! echo "$CONTAINERS" | grep "$1" > /dev/null; then
            echo -e "${RED}KO${YELLOW}: $1 container didnt restarted${NC}"
        else
            if echo "$CONTAINERS" | grep "$1" | grep "health: starting" > /dev/null; then
                    ATTEMPTS=0
                    until echo "$CONTAINERS" | grep -q "$1.*healthy" || [ "$ATTEMPTS" -ge "$TIMEOUT" ]; do
                        CONTAINERS=$($COMPOSE ps)
                        sleep 1
                        ((ATTEMPTS++))
                        if [ "$ATTEMPTS" -eq "$TIMEOUT" ]; then
                            echo -e "${RED}KO:${YELLOW} $1 timed out restarting after crash${NC}"
                        fi
                    done
            else
                    echo -e "${RED}KO${YELLOW}: $1 container didnt restarted${NC}"
            fi
            if echo "$CONTAINERS" | grep "$1" | grep "healthy" > /dev/null; then
                echo -e "${GREEN}OK${NC}"
            fi
            fi
    else
        echo -e "${RED}KO${NC}: Crash test (docker exec -it $1 ash -c \"kill -1 1\") failed${NC}"
    fi
    else
        echo -e "${YELLOW}$1: ${RED}KO${YELLOW}: No $1 container found${NC}"
    fi
    echo "$CONTAINERS" | grep "$1"
}

COMPOSE="docker compose -f $(dirname "$0")/../srcs/docker-compose.yml"
CONTAINERS=$($COMPOSE ps)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Crash testing ...${NC}"

crash_test "nginx"
crash_test "mariadb"
crash_test "wordpress"
