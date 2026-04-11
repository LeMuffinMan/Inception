#!/bin/bash

# =============================================================================
# lib/config.sh — Centralized configuration for all Inception check scripts
#
# This is the ONLY file you need to edit when adapting the scripts
# to your setup. All scripts source this file automatically.
# =============================================================================

# Login is derived from the local username — edit manually if it differs from your 42 login
LOGIN=$(whoami)

# For 42 subject, the domain name is such.
# Feel free to use the domain name of your choice.
DOMAIN="${LOGIN}.42.fr"

# this variable is used for the automatic secrets generation, using openssl or /dev/urandom as fallback
SECRET_LENGTH=32

# wordpress taking usually arround 20 secs to start, choosing a lower timeout length
# could invalid some tests
WAIT_TIMEOUT=45
RESTART_TIMEOUT=45

#Add in this array all credentials files you need to generate. It will be randomly generated to prevent leaking secrets
CREDENTIALS_FILES=("db_password.txt" "db_root_password.txt" "wp_admin_password.txt" "wp_user_password.txt" "ftp_pass.txt")

# Each container name must match the service name in docker-compose.yml
CONTAINER_MARIADB="mariadb"
CONTAINER_NGINX="nginx"
CONTAINER_WORDPRESS="wordpress"
CONTAINER_REDIS="redis"
CONTAINER_ADMINER="adminer"
CONTAINER_FTP="vsftpd"

CONTAINERS_TO_TEST=("$CONTAINER_REDIS" "$CONTAINER_WORDPRESS" "$CONTAINER_NGINX" "$CONTAINER_MARIADB" "$CONTAINER_ADMINER" "$CONTAINER_FTP")

VOLUME_MARIADB="srcs_mariadb_data"
VOLUME_WORDPRESS="srcs_wordpress_data"
VOLUME_NGINX="srcs_nginx_data"

# Theses variables are set to respect the tree example provided in the subject.
ROOT_DIR="$(dirname "$0")/.."
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
COMPOSE="docker compose -f ${COMPOSE_FILE}"
ENV_FILE="${ROOT_DIR}/.env"
SECRETS_DIR="${ROOT_DIR}/../secrets"
DB_SECRET_FILE="${SECRETS_DIR}/db_root_password.txt"

# These variables fits subject requirements :
# only one entrypoint to our network: nginx through port 443
# mariadb listening on port 3306
# nginx listening on port 9000
PORT_MARIADB_EXPECTED="3306/tcp"
PORT_NGINX_EXPECTED="0.0.0.0:443->443/tcp,"
PORT_WORDPRESS_EXPECTED="9000/tcp"

# these variables follow the subject requirements
TLS_ACCEPT=("1.2" "1.3")
TLS_REJECT=("1.1")

REQUIRED_ENV_VARS=(
    "DOMAIN_NAME"
    "MYSQL_DATABASE"
    "MYSQL_USER"
    "MYSQL_USER_EMAIL"
    "MYSQL_ADMIN_EMAIL"
    "WP_TITLE"
    "WP_USER"
    "WP_ADMIN_USER"
    "FTP_USER"
)
ADMIN_FORBIDDEN_PATTERN="^admin$|admin-|^administrator$"
