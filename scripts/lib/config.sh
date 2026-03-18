#!/bin/bash
# =============================================================================
# lib/config.sh — Centralized configuration for all Inception check scripts
#
# This is the ONLY file you need to edit when adapting the scripts
# to your setup. All scripts source this file automatically.
# =============================================================================

# Automatically, we set the <login> variable following the local username.
# Edit manualy if your local user not match your login.:w
LOGIN=$(whoami)

# For 42 subject, the domain name is such.
# Feel free to use the domain name of your choice.
DOMAIN="${LOGIN}.42.fr"

# this variable is used for the automatic secrets generation, using openssl or /dev/urandom as fallback
SECRET_LENGTH=32

# to customize your own mariadb/wordpress setup, edit theses variables
DEFAULT_MYSQL_USER="mysql_user"
DEFAULT_WP_ADMIN_USER="wp_su_${LOGIN}"
DEFAULT_WP_USER="wp_user_${LOGIN}"
DEFAULT_ADMIN_EMAIL="su@${LOGIN}.42.fr"
DEFAULT_USER_EMAIL="user@${LOGIN}.42.fr"

# wordpress taking usually arround 20 secs to start, choosing a lower timeout length
# could invalid some tests
WAIT_TIMEOUT=30
RESTART_TIMEOUT=30

# Name your volumes as you wish
VOLUME_MARIADB="srcs_mariadb_data"
VOLUME_WORDPRESS="srcs_wordpress_data"

# Theses variables are set to respect the tree example provided in the subject.
ROOT_DIR="$(dirname "$0")/.."
COMPOSE_FILE="${ROOT_DIR}/srcs/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/srcs/.env"
SECRETS_DIR="${ROOT_DIR}/secrets"
DB_SECRET_FILE="${SECRETS_DIR}/db_root_password.txt"

# the subject ask us to build a docker network with separates services for a minimal but DEFAULT_MYSQL_USER
# web stack
CONTAINER_MARIADB="mariadb"
CONTAINER_NGINX="nginx"
CONTAINER_WORDPRESS="wordpress"
CONTAINERS_TO_TEST=("$CONTAINER_NGINX" "$CONTAINER_MARIADB" "$CONTAINER_WORDPRESS")

# we need at least two volumes and their persistancy
VOLUMES_TO_CHECK=("mariadb" "wordpress")
VOLUME_HOST_PATH_PATTERN="/home/.*/data"

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
REQUIRED_ENV_VARS=("DOMAIN_NAME" "MYSQL_USER" "MYSQL_DATABASE")
ADMIN_FORBIDDEN_PATTERN="^admin$|admin-|^administrator$"
