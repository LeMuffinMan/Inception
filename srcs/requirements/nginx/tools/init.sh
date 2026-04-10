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
    # x509 : standard format : describes how the certificate is encoded (CN, O, C ...)
    #   - without the flag : it would ask a regular CSR : a certificate waiting to be signed by a CA
    #   - with the flag it becomes a self signed certificate, ready to use
    # nodes : no passphrase at startup
    # - days 365 : duration of validity of the certificate generated
    # -newkey rsa:2048 : we want a new RSA key 2048 bits
    # -keyout : where to write tu private keyout
    # -out where to write the certificate (public key and infos)
    # -subj : autofill infos that would have been asked interactively otherwise. CN is important : the browser will check it: is the certificate matches the domain i am trying to connect to ?
    # - we generate a RSA:2048 as a standard, higher bits would make it longer, and 2048 is sufficiently safe for our use case
    # - ECDSA could been a more moderne way for  encryption key generation
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=CO/ST=REG/L=City/O=42/CN=${DOMAIN_NAME}"

    log_info "Configuring server_name to ${DOMAIN_NAME} ..."
    sed -i "s/server_name localhost/server_name ${DOMAIN_NAME}/g" /etc/nginx/http.d/nginx.conf

    cp 404.html /var/www/html/404.html
fi

log_info "Starting nginx ..."
# Docker monitors PID 1 : we don't want nginx to run as daemon (fork and exit)
# thus, Docker sees nginx as PID 1 running in the container, it can forward signals and monitor it
exec nginx -g "daemon off;"
