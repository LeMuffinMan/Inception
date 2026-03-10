#!/bin/bash

crash_test() {
    if echo "$CONTAINERS" | grep "$1" > /dev/null; then
    echo -en "${YELLOW}Simulating a crash on $1: ${NC}docker exec -it $1 ash -c \"kill 1\"${NC}: "
    if docker exec -it $1 ash -c "kill 1"; then
        sleep 1
        CONTAINERS=$($COMPOSE ps)
        if ! echo "$CONTAINERS" | grep "$1" > /dev/null; then
            echo -e "${RED}KO${YELLOW}: $1 container didnt restarted${NC}"
        else
            if echo "$CONTAINERS" | grep "$1" | grep "health: starting" > /dev/null; then
                    ATTEMPTS=0
                    until echo "$CONTAINERS" | grep -q "$1.*healthy" || [ "$ATTEMPTS" -ge 5 ]; do
                        CONTAINERS=$($COMPOSE ps)
                        # echo -e "${YELLOW}Waiting $1 to restart ...${NC}"
                        sleep 2
                        ((ATTEMPTS++))
                        if [ "$ATTEMPTS" -eq 5 ]; then
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
        echo -e "${RED}KO${NC}: Crash test (docker exec -it $1 ash -c \"kill 1\") failed${NC}"
    fi
    else
        echo -e "${YELLOW}$1: ${RED}KO${YELLOW}: No $1 container found${NC}"
    fi
}

COMPOSE="docker compose -f $(dirname "$0")/../srcs/docker-compose.yml"
CONTAINERS=$($COMPOSE ps)
# echo "$CONTAINERS" | grep "nginx"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Crash testing ...${NC}"

crash_test "nginx"
crash_test "mariadb"

# if echo "$CONTAINERS" | grep "nginx" > /dev/null; then
#    echo -en "${YELLOW}Simulating a crash on nginx: ${NC}docker exec -it nginx ash -c \"kill 1\"${NC}: "
#    if docker exec -it nginx ash -c "kill 1"; then
#        sleep 1
#        CONTAINERS=$($COMPOSE ps)
#        if ! echo "$CONTAINERS" | grep "nginx" > /dev/null; then
#            echo -e "${RED}KO${YELLOW}: nginx container didnt restarted${NC}"
#        else
#            if echo "$CONTAINERS" | grep "nginx" | grep "health: starting" > /dev/null; then
#                 ATTEMPTS=0
#                 until echo "$CONTAINERS" | grep -q "nginx.*healthy" || [ "$ATTEMPTS" -ge 5 ]; do
#                     CONTAINERS=$($COMPOSE ps)
#                     # echo -e "${YELLOW}Waiting nginx to restart ...${NC}"
#                     sleep 2
#                     ((ATTEMPTS++))
#                     if [ "$ATTEMPTS" -eq 5 ]; then
#                         echo -e "${RED}KO:${YELLOW} nginx timed out restarting after crash${NC}"
#                     fi
#                 done
#            else
#                 echo -e "${RED}KO${YELLOW}: nginx container didnt restarted${NC}"
#            fi
#            if echo "$CONTAINERS" | grep "nginx" | grep "healthy" > /dev/null; then
#                echo -e "${GREEN}OK${NC}"
#            fi
#         fi
#    else
#        echo -e "${RED}KO${NC}: Crash test (docker exec -it nginx ash -c \"kill 1\") failed${NC}"
#    fi
# else
#     echo -e "${YELLOW}nginx: ${RED}KO${YELLOW}: No nginx container found${NC}"
# fi
