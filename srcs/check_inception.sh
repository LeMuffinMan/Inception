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

# network
# Nginx as only entrypoint through 443 and not 80
# no use of --link --links ...
# voir ou ils sont sur l'host et verifier le bind

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

echo
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

echo -e "   ${YELLOW}WordPress users:${NC}"

USERS=$(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N \
    --connect-timeout=2 \
    -e "SELECT user_login, user_email FROM ${MYSQL_DATABASE}.wp_users;" 2>/dev/null)

USER_COUNT=$(echo "$USERS" | grep -c ".")
if [ "$USER_COUNT" -ge 2 ]; then
    echo -e "      ${YELLOW}user count: ${GREEN}OK${NC}: $USER_COUNT users"
else
    echo -e "      ${YELLOW}user count: ${RED}KO${NC}: only $USER_COUNT user(s)"
fi

ADMIN_USER=$(docker exec mariadb mariadb -u root --password="${MYSQL_ROOT_PASSWORD}" -N \
    --connect-timeout=2 \
    -e "SELECT user_login FROM ${MYSQL_DATABASE}.wp_users
        JOIN ${MYSQL_DATABASE}.wp_usermeta ON wp_users.ID = wp_usermeta.user_id
        WHERE meta_key = 'wp_capabilities'
        AND meta_value LIKE '%administrator%';" 2>/dev/null)

if [ -z "$ADMIN_USER" ]; then
    echo -e "      ${YELLOW}admin exists: ${RED}KO${NC}"
else
    echo -e "      ${YELLOW}admin exists: ${GREEN}OK${NC}: $ADMIN_USER"
    if echo "$ADMIN_USER" | grep -iE "^admin$|admin-|^administrator$" > /dev/null; then
        echo -e "      ${YELLOW}admin username valid: ${RED}KO${NC}: '$ADMIN_USER' contains forbidden pattern"
    else
        echo -e "      ${YELLOW}admin username valid: ${GREEN}OK${NC}"
    fi
fi

echo -e "   ${YELLOW}domain name:${NC}"
DOMAIN_NAME="https://oelleaum.42.fr"
if cat /etc/hosts | grep "127.0.0.1	oelleaum.42.fr" > /dev/null; then
    echo -e "      ${YELLOW}custom domain name: ${GREEN}OK${NC}: ${DOMAIN_NAME}"
else
    echo -e "      ${YELLOW}custom domain name: ${GREEN}OK${NC}: ${DOMAIN_NAME}"
fi

if curl -k $DOMAIN_NAME > /dev/null 2>&1; then
    echo -e "      ${YELLOW}reachable: ${GREEN}OK${NC}"
else
    echo -e "      ${YELLOW}reachable: ${RED}KO${NC}"
fi

echo -e "${YELLOW}Network checks:${NC}"
echo

# Verifier que seul le port 443 est exposé sur le host (pas de port 80 ou autre)
EXPOSED_PORTS=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep -v "^NAME" | awk '{print $1, $2}')
FORBIDDEN_PORTS=$(echo "$EXPOSED_PORTS" | grep -v "nginx" | grep "0.0.0.0:")
if [ -z "$FORBIDDEN_PORTS" ]; then
    echo -e "   ${YELLOW}nginx only entrypoint: ${GREEN}OK${NC}"
else
    echo -e "   ${YELLOW}nginx only entrypoint: ${RED}KO${NC}: other containers expose ports: $FORBIDDEN_PORTS"
fi

PORT_80=$(echo "$EXPOSED_PORTS" | grep "nginx" | grep "0.0.0.0:80->")
if [ -z "$PORT_80" ]; then
    echo -e "   ${YELLOW}nginx no port 80: ${GREEN}OK${NC}"
else
    echo -e "   ${YELLOW}nginx no port 80: ${RED}KO${NC}"
fi

# No --link or links: in docker-compose.yml
if grep -qE "^\s+links:" srcs/docker-compose.yml; then
    echo -e "   ${YELLOW}no links: ${RED}KO${NC}: 'links:' found in docker-compose.yml"
else
    echo -e "   ${YELLOW}no links: ${GREEN}OK${NC}"
fi

# No network: host in docker-compose.yml
if grep -qE "network:\s+host" srcs/docker-compose.yml; then
    echo -e "   ${YELLOW}no network host: ${RED}KO${NC}: 'network: host' found in docker-compose.yml"
else
    echo -e "   ${YELLOW}no network host: ${GREEN}OK${NC}"
fi

echo

# Named volumes, no bind mounts
echo -e "${YELLOW}Volumes checks:${NC}"
echo

for VOL in mariadb wordpress; do
    SERVICE="srcs_${VOL}_data"
    if docker volume ls | grep -q "$SERVICE"; then
        # Verifier que c'est bien un named volume (driver local) et pas un bind mount
        DRIVER=$(docker volume inspect "$SERVICE" --format '{{.Driver}}')
        MOUNTPOINT=$(docker volume inspect "$SERVICE" --format '{{.Mountpoint}}')
        OPTIONS=$(docker volume inspect "$SERVICE" --format '{{.Options}}')

        if [ "$DRIVER" = "local" ]; then
            echo -e "   ${YELLOW}$VOL named volume: ${GREEN}OK${NC}"
        else
            echo -e "   ${YELLOW}$VOL named volume: ${RED}KO${NC}: driver is $DRIVER"
        fi

        # Verifier qu'il n'y a pas de bind mount pour ce volume dans compose
        if grep -A5 "volumes:" srcs/docker-compose.yml | grep -qE "\./|/home"; then
            echo -e "   ${YELLOW}$VOL no bind mount: ${RED}KO${NC}: bind mount detected in docker-compose.yml"
        else
            echo -e "   ${YELLOW}$VOL no bind mount: ${GREEN}OK${NC}"
        fi

        # Verifier la localisation sur le host
        EXPECTED="/home/${DOMAIN_NAME%%.*}/data"
        HOST_PATH=$(docker volume inspect "$SERVICE" --format '{{.Options.device}}' 2>/dev/null)
        if echo "$MOUNTPOINT" | grep -q "$EXPECTED" || echo "$HOST_PATH" | grep -q "$EXPECTED"; then
            echo -e "   ${YELLOW}$VOL host path: ${GREEN}OK${NC}: $MOUNTPOINT"
        else
            echo -e "   ${YELLOW}$VOL host path: ${RED}KO${NC}: expected $EXPECTED, got $MOUNTPOINT"
        fi
    else
        echo -e "   ${YELLOW}$VOL named volume: ${RED}KO${NC}: volume $SERVICE not found"
    fi
done
