#!/bin/bash

# =============================================================================
#  ██╗███╗   ██╗ ██████╗███████╗██████╗ ████████╗██╗ ██████╗ ███╗   ██╗
#  ██║████╗  ██║██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
#  ██║██╔██╗ ██║██║     █████╗  ██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║
#  ██║██║╚██╗██║██║     ██╔══╝  ██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║
#  ██║██║ ╚████║╚██████╗███████╗██║        ██║   ██║╚██████╔╝██║ ╚████║
#  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
#                          42 Project Check Script
# =============================================================================

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

# --- Helpers ------------------------------------------------------------------

section() {
    echo
    echo -e "${CYAN}${BOLD}┌─────────────────────────────────────────┐${NC}"
    printf "${CYAN}${BOLD}│  %-41s│${NC}\n" "$1"
    echo -e "${CYAN}${BOLD}└─────────────────────────────────────────┘${NC}"
}

LABEL_WIDTH=40

check() {
    local label="$1"
    local status="$2"   # "ok" | "ko"
    local detail="$3"   # optional extra info

    local pad=$(( LABEL_WIDTH - ${#label} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')

    if [ "$status" = "ok" ]; then
        printf "  ${WHITE}%s${NC}%s ${PASS}" "$label" "$spaces"
    else
        printf "  ${WHITE}%s${NC}%s ${FAIL}" "$label" "$spaces"
    fi

    if [ -n "$detail" ]; then
        echo -e "  ${DIM}→ ${detail}${NC}"
    else
        echo
    fi
}

wait_for() {
    local timeout="$1"; shift
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        eval "$@" && return 0
        sleep 1
        ((elapsed++))
    done
    return 1
}

# --- Wait for all containers to be up and healthy -------------------------

wait_for_containers() {
    local timeout=30
    local elapsed=0
    local containers=("$CONTAINER_MARIADB" "$CONTAINER_NGINX" "$CONTAINER_WORDPRESS")

    echo

    while [ $elapsed -lt $timeout ]; do
        CONTAINERS=$($COMPOSE ps 2>/dev/null)

        local all_ready=true
        local output=""

        for container in "${containers[@]}"; do
            local line
            line=$(echo "$CONTAINERS" | grep "$container")

            local status icon
            if ! echo "$line" | grep -q "Up"; then
                status="${RED}starting${NC}"; icon="${YELLOW}◌${NC}"; all_ready=false
            elif echo "$line" | grep -q "Restarting"; then
                status="${RED}restarting${NC}"; icon="${RED}✗${NC}"; all_ready=false
            elif echo "$line" | grep -q "unhealthy"; then
                status="${RED}unhealthy${NC}"; icon="${RED}✗${NC}"; all_ready=false
            elif echo "$line" | grep -q "health: starting"; then
                status="${YELLOW}health check...${NC}"; icon="${YELLOW}◌${NC}"; all_ready=false
            else
                status="${GREEN}ready${NC}"; icon="${GREEN}✓${NC}"
            fi

            output+="  ${icon}  ${WHITE}${container}${NC}  →  ${status}\n"
        done

        printf "\033[${#containers[@]}A" 2>/dev/null
        printf "%b" "$output"

        $all_ready && {
            echo
            printf "  ${GREEN}All containers ready${NC}  ${DIM}(${elapsed}s)${NC}\n"
            return 0
        }

        sleep 1
        ((elapsed++))
    done

    echo
    printf "  ${RED}${BOLD}Timeout: containers not ready after ${timeout}s${NC}\n"
    return 1
}

# --- Init ---------------------------------------------------------------------

set -a
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
MYSQL_ROOT_PASSWORD=$(cat "$DB_SECRET_FILE" 2>/dev/null)
set +a

COMPOSE="docker compose -f ${COMPOSE_FILE}"
CONTAINERS=$($COMPOSE ps 2>/dev/null)

echo
echo -e "${CYAN}${BOLD}  Inception — Project Check${NC}  ${DIM}login: ${LOGIN}  domain: ${DOMAIN}${NC}"

CONTAINER_MARIADB="mariadb"
CONTAINER_NGINX="nginx"
CONTAINER_WORDPRESS="wordpress"

PORT_MARIADB_EXPECTED="3306/tcp"
PORT_NGINX_EXPECTED="0.0.0.0:443->443/tcp,"
PORT_WORDPRESS_EXPECTED="9000/tcp"

ADMIN_FORBIDDEN_PATTERN="^admin$|admin-|^administrator$"

TLS_ACCEPT=("1.2" "1.3")
TLS_REJECT=("1.1")


# =============================================================================
# MARIADB
# =============================================================================
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
        check "volume" "ko" "volume $VOLUME_MARIADB not found"
    fi
else
    for label in "running" "healthy" "logs" "probe" "port" "volume"; do
        check "$label" "ko"
    done
fi


# =============================================================================
# NGINX
# =============================================================================
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


# =============================================================================
# WORDPRESS
# =============================================================================
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


# =============================================================================
# PROJECT INTEGRITY
# =============================================================================
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


# =============================================================================
# WORDPRESS USERS
# =============================================================================
section "WordPress Users"

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


# =============================================================================
# NETWORK
# =============================================================================
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

if grep -q "127.0.0.1	${DOMAIN}" /etc/hosts; then
    check "/etc/hosts entry" "ok" "127.0.0.1 → ${DOMAIN}"
else
    check "/etc/hosts entry" "ko" "missing: 127.0.0.1  ${DOMAIN}"
fi

echo

if ! wait_for_containers; then
    echo
    $COMPOSE ps
    exit 1
fi
