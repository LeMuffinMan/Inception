#!/bin/bash

# set -e
# set -x
# set -o pipefail

#checker les volumes persitants ?

#recup certaines variables uniquement ?
set -a
source "$(dirname "$0")/../srcs/.env"
set +a

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

COMPOSE="docker compose -f $(dirname "$0")/../srcs/docker-compose.yml"

echo -e "${YELLOW}Inception project check${NC}"
echo
CONTAINERS=$($COMPOSE ps)

echo -e "${YELLOW}Mariadb container:${NC} "
ATTEMPTS=0
until [ docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1 ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
    echo -e "${YELLOW}Waiting mariadb to be fully started ...${NC}"
    sleep 1
    ((ATTEMPTS++))
    if [ "$(echo "$ATTEMPTS")" -eq 5 ]; then
        echo -e "${YELLOW}Mariadb timed out:${NC}"
    fi
done
if echo "$CONTAINERS" | grep "mariadb" > /dev/null && echo "$CONTAINERS" | grep "Up" > /dev/null && ! echo "$CONTAINERS" | grep "Restarting"; then
    echo -e "   ${YELLOW}running: ${GREEN}OK${NC}"
    if  ! echo $CONTAINERS | grep "mariadb" | grep -q "unhealthy"; then
        echo -e "   ${YELLOW}healthy: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    fi

    if docker logs mariadb 2>&1 | grep -q "ready for connections"; then
        echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
    else
        ATTEMPTS=0
        while [ $(docker logs mariadb 2>&1 | grep -q "ready for connections") ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
            sleep 1
            ((ATTEMPTS++))
        done
        if docker logs mariadb 2>&1 | grep -q "ready for connections"; then
            echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
        else
            echo -e "   ${YELLOW}logs: ${RED}KO: timed out${NC}"
        fi
    fi
    ATTEMPTS=0
    until [ $(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1) ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
        sleep 1
        ((ATTEMPTS++))
        if [ "$(echo "$ATTEMPTS")" -eq 5 ]; then
            echo -e "${YELLOW}Probe mariadb timed out:${NC}"
        fi
    done
    PROBE=$(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 -e "SELECT 1" 2>&1)
    if [ "$(echo "$PROBE")" -eq 1 ]; then
        echo -e "   ${YELLOW}probe: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    fi
    PORTS=$(docker port mariadb)
    if [ "$(echo "$PORTS" | grep -c '3306/tcp')" -eq 2 ] && [ "$(echo "$PORTS" | wc -l)" -eq 2 ]; then
        echo -e "   ${YELLOW}port: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}port: ${RED}KO${NC}"
    fi
else
    echo -e "   ${YELLOW}running: ${RED}KO${NC}"
    echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    echo -e "   ${YELLOW}logs: ${RED}KO${NC}"
    echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    echo -e "   ${YELLOW}port: ${RED}KO${NC}"
    #tester les volumes
fi

if docker volume ls | grep -q "srcs_mariadb_data"; then
    MOUNTPOINT=$(docker volume inspect srcs_mariadb_data --format '{{ .Mountpoint }}')
    DATE=$(docker volume inspect srcs_mariadb_data --format '{{ .CreatedAt }}')
    echo -e "   ${YELLOW}volume: ${GREEN}OK${NC}: $MOUNTPOINT"
else
    echo -e "   ${YELLOW}volume: ${RED}KO${NC}"
fi
