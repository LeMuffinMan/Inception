#!/bin/bash

# set -e
# set -o pipefail

#checker les volumes persitants ?

#recup certaines variables uniquement ?
set -a
source "$(dirname "$0")/../srcs/.env"
set +a

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

COMPOSE="docker compose -f $(dirname "$0")/../srcs/docker-compose.yml"

echo "Inception project check"
echo
CONTAINERS=$($COMPOSE ps)

echo "Mariadb container: "
until docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting mariadb to be fully started ..."
    sleep 1
done
if echo "$CONTAINERS" | grep "mariadb" > /dev/null && echo "$CONTAINERS" | grep "Up" > /dev/null && ! echo "$CONTAINERS" | grep "Restarting"; then
    echo -e "   running: ${GREEN}OK${NC}"
    if  ! echo $CONTAINERS | grep "mariadb" | grep -q "unhealthy"; then
        echo -e "   healthy: ${GREEN}OK${NC}"
    else
        echo -e "   healthy: ${RED}KO${NC}"
    fi
    if docker logs mariadb 2>&1 | grep -q "ready for connections"; then
        echo -e "   logs: ${GREEN}OK${NC}"
    else
        echo -e "   logs: ${RED}KO${NC}"
    fi
    PROBE=$(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 -e "SELECT 1")
    if [ "$PROBE" -eq 1 ]; then
        echo -e "   probe: ${GREEN}OK${NC}"
    else
        echo -e "   probe: ${RED}KO${NC}"
    fi
    PORTS=$(docker port mariadb)
    if [ "$(echo "$PORTS" | grep -c '3306/tcp')" -eq 2 ] && [ "$(echo "$PORTS" | wc -l)" -eq 2 ]; then
        echo -e "   port: ${GREEN}OK${NC}"
    else
        echo -e "   port: ${RED}KO${NC}"
    fi
else
    echo -e "   running: ${RED}KO${NC}"
    echo -e "   healthy: ${RED}KO${NC}"
    echo -e "   logs: ${RED}KO${NC}"
    echo -e "   probe: ${RED}KO${NC}"
    echo -e "   port: ${RED}KO${NC}"
    #tester les volumes
fi

if docker volume ls | grep -q "srcs_mariadb_data"; then
    MOUNTPOINT=$(docker volume inspect srcs_mariadb_data --format '{{ .Mountpoint }}')
    echo -e "   volume: ${GREEN}OK${NC}: $MOUNTPOINT"
else
    echo -e "   volume: ${RED}KO${NC}"
fi
