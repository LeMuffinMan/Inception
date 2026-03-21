#!/bin/bash

# =============================================================================
#  ██╗███╗   ██╗ ██████╗███████╗██████╗ ████████╗██╗ ██████╗ ███╗   ██╗
#  ██║████╗  ██║██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
#  ██║██╔██╗ ██║██║     █████╗  ██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║
#  ██║██║╚██╗██║██║     ██╔══╝  ██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║
#  ██║██║ ╚████║╚██████╗███████╗██║        ██║   ██║╚██████╔╝██║ ╚████║
#  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
# =============================================================================

# edit scripts/lib/config.sh to customize your inception setup
# format.sh should not be edited
source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"


# LABEL_WIDTH=40

# --- Init ---------------------------------------------------------------------

set -a
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
MYSQL_ROOT_PASSWORD=$(cat "$DB_SECRET_FILE" 2>/dev/null)
set +a

COMPOSE="docker compose -f ${COMPOSE_FILE}"
CONTAINERS=$($COMPOSE ps 2>/dev/null)

echo
echo -e "${CYAN}${BOLD}  Inception — Project Check${NC}  ${DIM}login: ${LOGIN}  domain: ${DOMAIN}${NC}"

if ! wait_for_containers; then
    echo
    $COMPOSE ps
    exit 1
fi

# =============================================================================
# MARIADB
# =============================================================================
if [ -z $1 ] || [ "$1" == "mariadb" ]; then
    section "MariaDB"

    if echo "$CONTAINERS" | grep "$CONTAINER_MARIADB" | grep "Up" > /dev/null \
    && ! echo "$CONTAINERS" | grep "$CONTAINER_MARIADB" | grep "Restarting" > /dev/null; then
        check "running" "ok"

        if echo "$CONTAINERS" | grep "$CONTAINER_MARIADB" | grep -q "unhealthy"; then
            check "healthy" "ko"
        elif echo "$CONTAINERS" | grep "$CONTAINER_MARIADB" | grep -q "health: starting"; then
            printf "  ${WHITE}%-30s${NC} ${YELLOW}starting...${NC}\n" "healthy"
        else
            check "healthy" "ok"
        fi

        if wait_for $WAIT_TIMEOUT "docker logs $CONTAINER_MARIADB 2>&1 | grep -q 'ready for connections'"; then
            check "logs (ready for connections)" "ok"
        else
            check "logs (ready for connections)" "ko" "timed out after ${WAIT_TIMEOUT}s"
        fi

        PROBE=$(docker exec "$CONTAINER_MARIADB" mariadb -u root \
            --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 \
            -e "SELECT 1" 2>&1)
        if [ "$PROBE" = "1" ]; then
            check "probe (SELECT 1)" "ok"
        else
            check "probe (SELECT 1)" "ko"
        fi

        PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" \
            | grep "$CONTAINER_MARIADB" | awk '{print $2}')
        if [ "$PORT" = "$PORT_MARIADB_EXPECTED" ]; then
            check "port" "ok" "$PORT"
        else
            check "port" "ko" "got: $PORT  expected: $PORT_MARIADB_EXPECTED"
        fi

        if docker volume ls | grep -q "$VOLUME_MARIADB"; then
            HOST_PATH=$(docker volume inspect -f '{{ .Options.device }}' "$VOLUME_MARIADB")
            MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' "$VOLUME_MARIADB")
            check "volume" "ok" "${HOST_PATH} → ${MOUNTPOINT}"
        else
            check "volume" "ko" "volume ${VOLUME_MARIADB} not found"
        fi
    else
        for label in "running" "healthy" "logs" "probe" "port" "volume"; do
            check "$label" "ko"
        done
    fi
fi


# =============================================================================
# NGINX
# =============================================================================

if [ -z $1 ] || [ "$1" == "nginx" ]; then
    section "Nginx"

    if echo "$CONTAINERS" | grep "$CONTAINER_NGINX" | grep "Up" > /dev/null \
    && ! echo "$CONTAINERS" | grep "$CONTAINER_NGINX" | grep "Restarting" > /dev/null; then
        check "running" "ok"

        if echo "$CONTAINERS" | grep "$CONTAINER_NGINX" | grep -q "unhealthy"; then
            check "healthy" "ko"
        elif echo "$CONTAINERS" | grep "$CONTAINER_NGINX" | grep -q "health: starting"; then
            printf "  ${WHITE}%-30s${NC} ${YELLOW}starting...${NC}\n" "healthy"
        else
            check "healthy" "ok"
        fi

        if docker logs "$CONTAINER_NGINX" > /dev/null 2>&1; then
            check "logs" "ok"
        else
            check "logs" "ko"
        fi

        if curl -k "https://localhost:443" > /dev/null 2>&1; then
            check "probe (HTTPS)" "ok"
        else
            check "probe (HTTPS)" "ko"
        fi

        #-k ignores SSL certificate check, needed since we autosign our certs
        #-v verbose mode:
        TLS_VERSION=$(curl -k -v "https://localhost:443" 2>&1 | grep -o "TLSv1\.[0-9]" | sort -u)
        if [ -n "$TLS_VERSION" ]; then
            check "TLS version detected" "ok" "$TLS_VERSION"
        else
            check "TLS version detected" "ko"
        fi

        for VER in "${TLS_ACCEPT[@]}"; do
            if curl -k --tlsv${VER} "https://localhost:443" > /dev/null 2>&1; then
                check "TLSv${VER} accepted" "ok"
            else
                check "TLSv${VER} accepted" "ko"
            fi
        done

        for VER in "${TLS_REJECT[@]}"; do
            if curl -k --tlsv${VER} --tls-max ${VER} "https://localhost:443" 2>&1 \
            | grep -q "no protocols available"; then
                check "TLSv${VER} rejected" "ok"
            else
                check "TLSv${VER} rejected" "ko"
            fi
        done

        PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" \
            | grep "$CONTAINER_NGINX" | awk '{print $2}')
        if [ "$PORT" = "$PORT_NGINX_EXPECTED" ]; then
            check "port" "ok" "$PORT"
        else
            check "port" "ko" "got: $PORT  expected: $PORT_NGINX_EXPECTED"
        fi
    else
        for label in "running" "healthy" "logs" "probe" "TLS" "port"; do
            check "$label" "ko"
        done
    fi
fi

# =============================================================================
# WORDPRESS
# =============================================================================

if [ -z $1 ] || [ "$1" == "wordpress" ]; then
    section "WordPress"

    if echo "$CONTAINERS" | grep "$CONTAINER_WORDPRESS" | grep "Up" > /dev/null \
    && ! echo "$CONTAINERS" | grep "$CONTAINER_WORDPRESS" | grep "Restarting" > /dev/null; then
        check "running" "ok"

        if echo "$CONTAINERS" | grep "$CONTAINER_WORDPRESS" | grep -q "unhealthy"; then
            check "healthy" "ko"
        elif echo "$CONTAINERS" | grep "$CONTAINER_WORDPRESS" | grep -q "health: starting"; then
            printf "  ${WHITE}%-30s${NC} ${YELLOW}starting...${NC}\n" "healthy"
        else
            check "healthy" "ok"
        fi

        LOG_OK=false
        ELAPSED=0
        while [ $ELAPSED -lt $WAIT_TIMEOUT ]; do
            if docker logs "$CONTAINER_WORDPRESS" 2>&1 \
            | grep -qE "Wordpress successfully installed|Wordpress already installed and configured"; then
                LOG_OK=true; break
            fi
            sleep 1; ((ELAPSED++))
        done
        if $LOG_OK; then
            check "logs (WP installed)" "ok"
        else
            check "logs (WP installed)" "ko" "timed out after ${WAIT_TIMEOUT}s"
        fi

        PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" \
            | grep "$CONTAINER_WORDPRESS" | awk '{print $2}')
        if [ "$PORT" = "$PORT_WORDPRESS_EXPECTED" ]; then
            check "port" "ok" "$PORT"
        else
            check "port" "ko" "got: $PORT  expected: $PORT_WORDPRESS_EXPECTED"
        fi

        if docker volume ls | grep -q "$VOLUME_WORDPRESS"; then
            HOST_PATH=$(docker volume inspect -f '{{ .Options.device }}' "$VOLUME_WORDPRESS")
            MOUNTPOINT=$(docker volume inspect -f '{{ .Mountpoint }}' "$VOLUME_WORDPRESS")
            check "volume" "ok" "${HOST_PATH} → ${MOUNTPOINT}"
        else
            check "volume" "ko" "volume $VOLUME_WORDPRESS not found"
        fi
    else
        for label in "running" "healthy" "logs" "port" "volume"; do
            check "$label" "ko"
        done
    fi
    USERS=$(docker exec "$CONTAINER_MARIADB" mariadb -u root \
        --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 \
        -e "SELECT user_login, user_email FROM ${MYSQL_DATABASE}.wp_users;" 2>/dev/null)

    USER_COUNT=$(echo "$USERS" | grep -c ".")
    if [ "$USER_COUNT" -ge 2 ]; then
        check "user count (≥ 2)" "ok" "${USER_COUNT} users"
    else
        check "user count (≥ 2)" "ko" "only ${USER_COUNT} user(s)"
    fi

    ADMIN_USER=$(docker exec "$CONTAINER_MARIADB" mariadb -u root \
        --password="${MYSQL_ROOT_PASSWORD}" -N --connect-timeout=2 \
        -e "SELECT user_login FROM ${MYSQL_DATABASE}.wp_users
            JOIN ${MYSQL_DATABASE}.wp_usermeta ON wp_users.ID = wp_usermeta.user_id
            WHERE meta_key = 'wp_capabilities'
            AND meta_value LIKE '%administrator%';" 2>/dev/null)

    if [ -z "$ADMIN_USER" ]; then
        check "admin exists" "ko"
    else
        check "admin exists" "ok" "$ADMIN_USER"
        if echo "$ADMIN_USER" | grep -iE "$ADMIN_FORBIDDEN_PATTERN" > /dev/null; then
            check "admin username (no forbidden pattern)" "ko" "'$ADMIN_USER' matches forbidden pattern"
        else
            check "admin username (no forbidden pattern)" "ok"
        fi
    fi
fi

# =============================================================================
# REDIS
# =============================================================================
if [ -z $1 ] || [ "$1" == "redis" ]; then
    section "Redis"

    if echo "$CONTAINERS" | grep "$CONTAINER_REDIS" | grep "Up" > /dev/null \
    && ! echo "$CONTAINERS" | grep "$CONTAINER_REDIS" | grep "Restarting" > /dev/null; then
        check "running" "ok"

        if echo "$CONTAINERS" | grep "$CONTAINER_REDIS" | grep -q "unhealthy"; then
            check "healthy" "ko"
        elif echo "$CONTAINERS" | grep "$CONTAINER_REDIS" | grep -q "health: starting"; then
            printf "  ${WHITE}%-30s${NC} ${YELLOW}starting...${NC}\n" "healthy"
        else
            check "healthy" "ok"
        fi

        REDIS_PING=$(docker exec "$CONTAINER_REDIS" redis-cli ping 2>/dev/null)
        if [ "$REDIS_PING" = "PONG" ]; then
            check "probe (PING)" "ok"
        else
            check "probe (PING)" "ko" "got: $REDIS_PING"
        fi

        #We curl our site to create at least 1 key to check for redis
        # curl -k "https://${DOMAIN}" > /dev/null 2>&1
        # sleep 1

        REDIS_KEYS=$(docker exec "$CONTAINER_REDIS" redis-cli dbsize 2>/dev/null)
        if [ "$REDIS_KEYS" -gt 0 ] 2>/dev/null; then
            check "cache populated (keys > 0)" "ok" "${REDIS_KEYS} keys"
        else
            check "cache populated (keys > 0)" "ko" "0 keys — WordPress may not be using Redis"
        fi

        REDIS_STATUS=$(docker exec "$CONTAINER_WORDPRESS" wp redis status --path=/var/www/html --allow-root 2>/dev/null)
        if echo "$REDIS_STATUS" | grep -q "Drop-in: Valid" && echo "$REDIS_STATUS" | grep -q "Disabled: No"; then
            REDIS_VERSION=$(echo "$REDIS_STATUS" | grep "Redis Version:")
            check "wp redis status" "ok" "$REDIS_VERSION"
        else
            check "wp redis status" "ko"
        fi

        REDIS_PORT=$(echo "$REDIS_STATUS" | grep WP_REDIS_PORT | awk -F':' '{{print $2}}' | tr -d ' ')
        if [ $REDIS_PORT -ne 6379 ]; then
            check "port" "ko"
        else
            check "port" "ok" "$REDIS_PORT"
        fi

    else
        for label in "running" "healthy" "probe" "cache populated" "wp redis status"; do
            check "$label" "ko"
        done
    fi
fi

# =============================================================================
# ADMINER
# =============================================================================
if [ -z $1 ] || [ "$1" == "adminer" ]; then
    section "Adminer"

    if echo "$CONTAINERS" | grep "$CONTAINER_ADMINER" | grep "Up" > /dev/null \
    && ! echo "$CONTAINERS" | grep "$CONTAINER_ADMINER" | grep "Restarting" > /dev/null; then
        check "running" "ok"

        if echo "$CONTAINERS" | grep "$CONTAINER_ADMINER" | grep -q "unhealthy"; then
            check "healthy" "ko"
        elif echo "$CONTAINERS" | grep "$CONTAINER_ADMINER" | grep -q "health: starting"; then
            printf "  ${WHITE}%-30s${NC} ${YELLOW}starting...${NC}\n" "healthy"
        else
            check "healthy" "ok"
        fi

        # Probe HTTP — Adminer should answer on its internal port
        ADMINER_PROBE=$(docker exec "$CONTAINER_ADMINER" \
            wget -qO- http://localhost:8080 2>/dev/null | grep -c "adminer" || echo 0)
        if [ "$ADMINER_PROBE" -gt 0 ]; then
            check "probe (HTTP 8080)" "ok"
        else
            check "probe (HTTP 8080)" "ko"
        fi

        # nginx proxy
        HTTP_CODE=$(curl -k -o /dev/null -s -w "%{http_code}" "https://${DOMAIN}/adminer")
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
            check "reachable via nginx (/adminer)" "ok" "HTTP $HTTP_CODE"
        else
            check "reachable via nginx (/adminer)" "ko" "HTTP $HTTP_CODE"
        fi

        # Port not exposed on host, only nginx as entrypoint
        PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" \
            | grep "$CONTAINER_ADMINER" | awk '{print $2}')
        if echo "$PORT" | grep -q "0.0.0.0"; then
            check "port not exposed on host" "ko" "got: $PORT"
        else
            check "port not exposed on host" "ok"
        fi

        # Adminer connection to Mariadb
        DB_PROBE=$(docker exec "$CONTAINER_ADMINER" \
            wget -qO- --post-data="auth[driver]=server&auth[server]=${CONTAINER_MARIADB}&auth[username]=root&auth[password]=${MYSQL_ROOT_PASSWORD}&auth[db]=${MYSQL_DATABASE}" \
            http://localhost:8080 2>/dev/null | grep -c "logout" || echo 0)
        if [ "$DB_PROBE" -gt 0 ]; then
            check "connects to MariaDB" "ok"
        else
            check "connects to MariaDB" "ko" "check credentials or network"
        fi

    else
        for label in "running" "healthy" "probe" "reachable via nginx" "port not exposed" "connects to MariaDB"; do
            check "$label" "ko"
        done
    fi
fi

# =============================================================================
# PROJECT INTEGRITY
# =============================================================================
if [ -z $1 ] || [ "$1" == "integrity" ]; then
    section "Project Integrity"

    PASS_FOUND=$(grep -rli "password" srcs/requirements/*/Dockerfile 2>/dev/null)
    if [ -z "$PASS_FOUND" ]; then
        check "no password in Dockerfiles" "ok"
    else
        check "no password in Dockerfiles" "ko" "found in: $PASS_FOUND"
    fi

    if [ -f "$ENV_FILE" ]; then
        check ".env exists" "ok" "$ENV_FILE"
        for VAR in "${REQUIRED_ENV_VARS[@]}"; do
            if grep -q "^${VAR}=" "$ENV_FILE"; then
                check ".env → $VAR" "ok"
            else
                check ".env → $VAR" "ko" "missing"
            fi
        done
    else
        check ".env exists" "ko" "$ENV_FILE not found"
    fi

    if grep -q ":latest" "$COMPOSE_FILE" 2>/dev/null; then
        check "no 'latest' tag in compose" "ko"
    else
        check "no 'latest' tag in compose" "ok"
    fi

    ALLOWED_BASES="alpine debian"
    for DOCKERFILE in srcs/requirements/*/Dockerfile; do
        SERVICE=$(echo "$DOCKERFILE" | awk -F'/' '{print $(NF-1)}')
        FROM_LINE=$(grep -i "^FROM" "$DOCKERFILE" | head -1 | awk '{print $2}')
        BASE=$(echo "$FROM_LINE" | cut -d':' -f1)
        TAG=$(echo "$FROM_LINE" | cut -d':' -f2)

        if echo "$ALLOWED_BASES" | grep -qw "$BASE"; then
            if [ "$TAG" = "latest" ] || [ -z "$TAG" ]; then
                check "base image: $SERVICE" "ko" "latest or missing tag ($FROM_LINE)"
            else
                check "base image: $SERVICE" "ok" "$FROM_LINE"
            fi
        else
            check "base image: $SERVICE" "ko" "forbidden base ($FROM_LINE)"
        fi
    done

    EXTERNAL_IMAGE=$(grep -E "^\s+image:" "$COMPOSE_FILE" | grep -v "^\s*#")
    if [ -z "$EXTERNAL_IMAGE" ]; then
        check "no external image in compose" "ok"
    else
        check "no external image in compose" "ko" "$EXTERNAL_IMAGE"
    fi
fi

# =============================================================================
# NETWORK
# =============================================================================

if [ -z $1 ] || [ "$1" == "network" ]; then
    section "Network"

    EXPOSED_PORTS=$(docker ps --format "{{.Names}}\t{{.Ports}}")

    FORBIDDEN_PORTS=$(echo "$EXPOSED_PORTS" | grep -v "$CONTAINER_NGINX" | grep "0.0.0.0:")
    if [ -z "$FORBIDDEN_PORTS" ]; then
        check "nginx only entrypoint" "ok"
    else
        check "nginx only entrypoint" "ko" "$FORBIDDEN_PORTS"
    fi

    PORT_80=$(echo "$EXPOSED_PORTS" | grep "$CONTAINER_NGINX" | grep "0.0.0.0:80->")
    if [ -z "$PORT_80" ]; then
        check "nginx: no port 80" "ok"
    else
        check "nginx: no port 80" "ko"
    fi

    if grep -qE "^\s+links:" "$COMPOSE_FILE"; then
        check "no 'links:' in compose" "ko"
    else
        check "no 'links:' in compose" "ok"
    fi

    if grep -qE "network:\s+host" "$COMPOSE_FILE"; then
        check "no 'network: host' in compose" "ko"
    else
        check "no 'network: host' in compose" "ok"
    fi

    if curl -k "https://${DOMAIN}" > /dev/null 2>&1; then
        check "domain reachable (${DOMAIN})" "ok"
    else
        check "domain reachable (${DOMAIN})" "ko"
    fi

    if grep "^127\.0\.0\.1" /etc/hosts | grep -q $(whoami).42.fr; then
        check "/etc/hosts entry" "ok" "127.0.0.1 → ${DOMAIN}"
    else
        check "/etc/hosts entry" "ko" "missing: 127.0.0.1  ${DOMAIN}"
    fi
fi

echo
