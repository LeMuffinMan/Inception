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
if echo "$CONTAINERS" | grep "mariadb" | grep "Up" > /dev/null && ! echo "$CONTAINERS" | grep "mariadb" | grep "Restarting"; then
    echo -e "   ${YELLOW}running: ${GREEN}OK${NC}"
    if  ! echo "$CONTAINERS" | grep "mariadb" | grep -q "unhealthy"; then
        if echo "$CONTAINERS" | grep "mariadb" | grep -q "health: starting"; then
            echo -e "   ${YELLOW}healthy: starting...${NC}"
        else
            echo -e "   ${YELLOW}healthy: ${GREEN}OK${NC}"
        fi
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
fi

if docker volume ls | grep -q "srcs_mariadb_data"; then
    VOL=srcs_mariadb_data
    HOST_PATH=$(docker volume inspect -f '{{ .Options.device }}' $VOL)
    MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' $VOL)
    DATE=$(docker volume inspect srcs_mariadb_data --format '{{ .CreatedAt }}')
    echo -e "   ${YELLOW}volume: ${GREEN}OK${NC}: $HOST_PATH:$MOUNTPOINT"
else
    echo -e "   ${YELLOW}volume: ${RED}KO${NC}"
fi

echo
echo -e "${YELLOW}Nginx container:${NC} "
ATTEMPTS=0
# until [ docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1 ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
#     echo -e "${YELLOW}Waiting mariadb to be fully started ...${NC}"
#     sleep 1
#     ((ATTEMPTS++))
#     if [ "$(echo "$ATTEMPTS")" -eq 5 ]; then
#         echo -e "${YELLOW}Mariadb timed out:${NC}"
#     fi
# done
if echo "$CONTAINERS" | grep "nginx" | grep "Up" > /dev/null && ! echo "$CONTAINERS" | grep "nginx" | grep "Restarting"; then
    echo -e "   ${YELLOW}running: ${GREEN}OK${NC}"
    if  echo "$CONTAINERS" | grep "nginx" | grep -q "unhealthy" > /dev/null; then
        echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    else
        if echo "$CONTAINERS" | grep "nginx" | grep -q "health: starting"; then
            echo -e "   ${YELLOW}healthy: starting...${NC}"
        else
            echo -e "   ${YELLOW}healthy: ${GREEN}OK${NC}"
        fi
    fi

    if docker logs nginx > /dev/null 2>&1; then
        echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}logs: ${RED}KO: timed out${NC}"
    fi

    if curl -k https://localhost:443 2>&1 | grep "Hello from nginx" > /dev/null; then
        echo -e "   ${YELLOW}probe: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    fi

    TLS_VERSION=$(curl -k -v https://localhost:443 2>&1 | grep -o "TLSv1\.[0-9]" | sort -u)
    if [ -n "$TLS_VERSION" ]; then
        echo -e "   ${YELLOW}TLS: ${GREEN}${TLS_VERSION}${NC}"
    else
        echo -e "   ${YELLOW}TLS: ${RED}KO${NC}"
    fi

    if curl -k --tlsv1.2 https://localhost:443 2>&1 | grep "Hello from nginx" > /dev/null; then
        echo -e "   ${YELLOW}TLSv1.2: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.2: ${RED}KO${NC}"
    fi

    if curl -k --tlsv1.3 https://localhost:443 2>&1 | grep "Hello from nginx" > /dev/null; then
        echo -e "   ${YELLOW}TLSv1.3: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.3: ${RED}KO${NC}"
    fi

    if curl -k --tlsv1.1 --tls-max 1.1  https://localhost:443 2>&1 | grep "curl: (35) TLS connect error: error:0A0000BF:SSL routines::no protocols available" > /dev/null; then
        echo -e "   ${YELLOW}TLSv1.1 denial: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.1 denial: ${RED}KO${NC}"
    fi
    # Logs / prob nginx avec TLS :
    # probe :
    # curl -k https://localhost:443 -> should return hello from nginx AND leave a line in /var/log/nginx/access.Logs
    #
    # check which TLS in use
    # curl -k -v https://localhost:443 2>&1 | grep "SSL connection using TLS" -> doit return une line AND leave a line /var/log/nginx/access.logs
    #
    # Forced TLSv1.2
    # curl -k --tlsv1.2 https://localhost:443 2>&1 -> doit renvoyer le contenu de la page et laisser une line dasn access
    #
    # Forced TLSv1.3
    # curl -k --tlsv1.3 https://localhost:443 2>&1 -> doit renvoyer le contenu de la page et laisser une line dasn access
    #
    # TLSv1.1 should be refused
    # curl -k --tlsv1.1 --tls-max 1.1  https://localhost:443 2>&1 -> doit return "curl: (35) TLS connect error: error:0A0000BF:SSL routines::no protocols available" ET une ligne specifique dans access


    # comment avoir les logs avec docker logs ?
    # if docker logs nginx 2>&1 | grep -q "ready for connections"; then
    #     echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
    # else
        # ATTEMPTS=0
        # while [ $(docker logs mariadb 2>&1 | grep -q "ready for connections") ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
        #     sleep 1
        #     ((ATTEMPTS++))
        # done
        # if docker logs nginx 2>&1 | grep -q "ready for connections"; then
        #     echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
        # else
        #     echo -e "   ${YELLOW}logs: ${RED}KO: timed out${NC}"
        # fi
    # fi
    # ATTEMPTS=0
    # until [ $(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1) ] || [ "$(echo "$ATTEMPTS")" -lt 5 ]; do
    #     sleep 1
    #     ((ATTEMPTS++))
    #     if [ "$(echo "$ATTEMPTS")" -eq 5 ]; then
    #         echo -e "${YELLOW}Probe mariadb timed out:${NC}"
    #     fi
    # done
    # PROBE=$(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 -e "SELECT 1" 2>&1)
    # if [ "$(echo "$PROBE")" -eq 1 ]; then
    #     echo -e "   ${YELLOW}probe: ${GREEN}OK${NC}"
    # else
    #     echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    # fi
    PORTS=$(docker port nginx)
    #grep une ligne entiere !
    if [ "$(echo "$PORTS" | grep -c '443/tcp')" -eq 2 ] && [ "$(echo "$PORTS" | wc -l)" -eq 2 ]; then
        #afficher le port si incorrect
        echo -e "   ${YELLOW}port: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}port: ${RED}KO${NC}"
    fi
else
    echo -e "   ${YELLOW}running: ${RED}KO${NC}"
    echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    # echo -e "   ${YELLOW}logs: ${RED}KO${NC}"
    # echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    echo -e "   ${YELLOW}port: ${RED}KO${NC}"
fi

# if docker volume ls | grep -q "srcs_mariadb_data"; then
#     MOUNTPOINT=$(docker volume inspect srcs_mariadb_data --format '{{ .Mountpoint }}')
#     DATE=$(docker volume inspect srcs_mariadb_data --format '{{ .CreatedAt }}')
#     echo -e "   ${YELLOW}volume: ${GREEN}OK${NC}: $MOUNTPOINT"
# else
#     echo -e "   ${YELLOW}volume: ${RED}KO${NC}"
# fi
