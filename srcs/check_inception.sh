#!/bin/bash

set -a
source "$(dirname "$0")/../srcs/.env"
MYSQL_ROOT_PASSWORD=$(cat secrets/db_root_password.txt)
set +a

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

COMPOSE="docker compose -f $(dirname "$0")/../srcs/docker-compose.yml"

echo -e "${YELLOW}Inception project check${NC}"
echo

# verifier si mdp / admin present dans le projet
# checker le .env et ses variables
# checker dockerhub et bien images locales, pas de latets
#
# network
# Nginx as only entrypoint through 443 and not 80
# no use of --link --links ...
# verifier si deux named volumes existent bien
# voir ou ils sont sur l'host et verifier le bind
#
# pour chqaue container verifier le restart on failure
#
# checker /etc/hosts pour la redirection localhost
# checker le curl -k https://oelleaum.42.fr


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

    PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep mariadb | awk '{print $2}')
    if [ "$PORT" == '0.0.0.0:3306->3306/tcp,' ]; then
        echo -e "   ${YELLOW}ports: ${GREEN}OK${NC}: $PORT"
    else
        echo -e "   ${YELLOW}port: ${RED}KO${NC}: $PORT"
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

    if docker logs nginx > /dev/null > /dev/null 2>&1; then
        echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}logs: ${RED}KO: timed out${NC}"
    fi

    if curl -k https://localhost:443 > /dev/null 2>&1; then
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

    if curl -k --tlsv1.2 https://localhost:443 > /dev/null 2>&1; then
        echo -e "   ${YELLOW}TLSv1.2: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.2: ${RED}KO${NC}"
    fi

    if curl -k --tlsv1.3 https://localhost:443 > /dev/null 2>&1; then
        echo -e "   ${YELLOW}TLSv1.3: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.3: ${RED}KO${NC}"
    fi

    if curl -k --tlsv1.1 --tls-max 1.1  https://localhost:443 2>&1 | grep "curl: (35) TLS connect error: error:0A0000BF:SSL routines::no protocols available" > /dev/null; then
        echo -e "   ${YELLOW}TLSv1.1 denial: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}TLSv1.1 denial: ${RED}KO${NC}"
    fi

    PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep nginx | awk '{print $2}')
    if [ "$PORT"  = "0.0.0.0:443->443/tcp," ]; then
        echo -e "   ${YELLOW}ports: ${GREEN}OK${NC}: $PORT"
    else
        echo -e "   ${YELLOW}port: ${RED}KO${NC}: $PORT"
    fi
else
    echo -e "   ${YELLOW}running: ${RED}KO${NC}"
    echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    echo -e "   ${YELLOW}logs: ${RED}KO${NC}"
    echo -e "   ${YELLOW}probe: ${RED}KO${NC}"
    echo -e "   ${YELLOW}port: ${RED}KO${NC}"
fi

echo
echo -e "${YELLOW}Wordpress container:${NC} "

if echo "$CONTAINERS" | grep "wordpress" | grep "Up" > /dev/null && ! echo "$CONTAINERS" | grep "wordpress" | grep "Restarting"; then
    echo -e "   ${YELLOW}running: ${GREEN}OK${NC}"
    if  echo "$CONTAINERS" | grep "wordpress" | grep -q "unhealthy" > /dev/null; then
        echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    else
        if echo "$CONTAINERS" | grep "wordpress" | grep -q "health: starting"; then
            echo -e "   ${YELLOW}healthy: starting...${NC}"
        else
            echo -e "   ${YELLOW}healthy: ${GREEN}OK${NC}"
        fi
    fi

    TIMEOUT=15
    ELAPSED=0
    INTERVAL=1
    LOG_OK=false

    while [ $ELAPSED -lt $TIMEOUT ]; do
        if docker logs wordpress 2>&1 | grep -q "Wordpress successfully installed" \
        || docker logs wordpress 2>&1 | grep -q "Wordpress already installed and configured"; then
            LOG_OK=true
            break
        fi
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

    if [ "$LOG_OK" = true ]; then
        echo -e "   ${YELLOW}logs: ${GREEN}OK${NC}"
    else
        echo -e "   ${YELLOW}logs: ${RED}KO: timed out${NC}"
    fi

    PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep wordpress | awk '{print $2}')
    if [ "$PORT" == "9000/tcp" ]; then
        echo -e "   ${YELLOW}ports: ${GREEN}OK${NC}: $PORT"
    else
        echo -e "   ${YELLOW}port: ${RED}KO${NC}: $PORT"
    fi

    if docker volume ls | grep -q "srcs_wordpress_data"; then
        VOL=srcs_wordpress_data
        HOST_PATH=$(docker volume inspect -f '{{ .Options.device }}' $VOL)
        MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' $VOL)
        DATE=$(docker volume inspect srcs_wordpress_data --format '{{ .CreatedAt }}')
        echo -e "   ${YELLOW}volume: ${GREEN}OK${NC}: $HOST_PATH:$MOUNTPOINT"
    else
        echo -e "   ${YELLOW}volume: ${RED}KO${NC}"
    fi

else
    echo -e "   ${YELLOW}running: ${RED}KO${NC}"
    echo -e "   ${YELLOW}healthy: ${RED}KO${NC}"
    echo -e "   ${YELLOW}logs: ${RED}KO${NC}"
    echo -e "   ${YELLOW}port: ${RED}KO${NC}"
    echo -e "   ${YELLOW}volume: ${RED}KO${NC}"
fi

echo -e "${YELLOW}Project integrity checks:${NC}"

PASS_FOUND=$(grep -rli "password" srcs/requirements/*/Dockerfile 2>/dev/null)
if [ -z "$PASS_FOUND" ]; then
    echo -e "   ${YELLOW}no password in Dockerfiles: ${GREEN}OK${NC}"
else
    echo -e "   ${YELLOW}no password in Dockerfiles: ${RED}KO${NC}: found in $PASS_FOUND"
fi

if [ -f "srcs/.env" ]; then
    echo -e "   ${YELLOW}.env exists: ${GREEN}OK${NC}"
    for VAR in DOMAIN_NAME MYSQL_USER MYSQL_DATABASE; do
        if grep -q "^${VAR}=" srcs/.env; then
            echo -e "   ${YELLOW}.env $VAR: ${GREEN}OK${NC}"
        else
            echo -e "   ${YELLOW}.env $VAR: ${RED}KO (missing)${NC}"
        fi
    done
else
    echo -e "   ${YELLOW}.env exists: ${RED}KO${NC}"
fi

if grep -q ":latest" srcs/docker-compose.yml 2>/dev/null; then
    echo -e "   ${YELLOW}no 'latest' tag: ${RED}KO${NC}"
else
    echo -e "   ${YELLOW}no 'latest' tag: ${GREEN}OK${NC}"
fi

ALLOWED_BASES="alpine debian"
for DOCKERFILE in srcs/requirements/*/Dockerfile; do
    SERVICE=$(echo "$DOCKERFILE" | awk -F'/' '{print $(NF-1)}')
    FROM_LINE=$(grep -i "^FROM" "$DOCKERFILE" | head -1 | awk '{print $2}')
    BASE=$(echo "$FROM_LINE" | cut -d':' -f1)
    TAG=$(echo "$FROM_LINE" | cut -d':' -f2)

    if echo "$ALLOWED_BASES" | grep -qw "$BASE"; then
        if [ "$TAG" = "latest" ] || [ -z "$TAG" ]; then
            echo -e "   ${YELLOW}$SERVICE base image: ${RED}KO (latest or no tag)${NC}"
        else
            echo -e "   ${YELLOW}$SERVICE base image: ${GREEN}OK${NC}: $FROM_LINE"
        fi
    else
        echo -e "   ${YELLOW}$SERVICE base image: ${RED}KO (forbidden base: $FROM_LINE)${NC}"
    fi
done

EXTERNAL_IMAGE=$(grep -E "^\s+image:" srcs/docker-compose.yml | grep -v "^\s*#")
if [ -z "$EXTERNAL_IMAGE" ]; then
    echo -e "   ${YELLOW}no external image in compose: ${GREEN}OK${NC}"
else
    echo -e "   ${YELLOW}no external image in compose: ${RED}KO${NC}: $EXTERNAL_IMAGE"
fi

echo
