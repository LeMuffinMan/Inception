#!/bin/sh

# --- Colors & log functions ---------------------------------------------------
NC='\033[0m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'
log_info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
# ------------------------------------------------------------------------------

if [ ! -f /etc/nginx/ssl/cert.pem ]; then
    mkdir -p /etc/nginx/ssl

    log_info "Generating self-signed TLS certificate ..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=CO/ST=REG/L=City/O=42/CN=${DOMAIN_NAME}"

    log_info "Configuring server_name to ${DOMAIN_NAME} ..."
    sed -i "s/server_name localhost/server_name ${DOMAIN_NAME}/g" /etc/nginx/http.d/nginx.conf

    cp 404.html /var/www/html/404.html
fi

log_info "Starting nginx ..."
exec nginx -g "daemon off;"
