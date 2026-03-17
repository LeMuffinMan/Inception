#!/bin/bash
# =============================================================================
# lib/config.sh — Centralized configuration for all Inception check scripts
#
# This is the ONLY file you need to edit when adapting the scripts
# to your setup. All scripts source this file automatically.
# =============================================================================

LOGIN=$(whoami)
DOMAIN="${LOGIN}.42.fr"

ROOT_DIR="$(dirname "$0")/.."
COMPOSE_FILE="${ROOT_DIR}/srcs/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/srcs/.env"
SECRETS_DIR="${ROOT_DIR}/secrets"
DB_SECRET_FILE="${SECRETS_DIR}/db_root_password.txt"

WAIT_TIMEOUT=30
RESTART_TIMEOUT=30

CONTAINER_MARIADB="mariadb"
CONTAINER_NGINX="nginx"
CONTAINER_WORDPRESS="wordpress"

CONTAINERS_TO_TEST=("$CONTAINER_NGINX" "$CONTAINER_MARIADB" "$CONTAINER_WORDPRESS")

VOLUME_MARIADB="srcs_mariadb_data"
VOLUME_WORDPRESS="srcs_wordpress_data"

VOLUMES_TO_CHECK=("mariadb" "wordpress")

VOLUME_HOST_PATH_PATTERN="/home/.*/data"

PORT_MARIADB_EXPECTED="3306/tcp"
PORT_NGINX_EXPECTED="0.0.0.0:443->443/tcp,"
PORT_WORDPRESS_EXPECTED="9000/tcp"

TLS_ACCEPT=("1.2" "1.3")
TLS_REJECT=("1.1")

REQUIRED_ENV_VARS=("DOMAIN_NAME" "MYSQL_USER" "MYSQL_DATABASE")
ADMIN_FORBIDDEN_PATTERN="^admin$|admin-|^administrator$"

DEFAULT_MYSQL_USER="mysql_user"
DEFAULT_WP_ADMIN_USER="wp_su_${LOGIN}"
DEFAULT_WP_USER="wp_user_${LOGIN}"
DEFAULT_ADMIN_EMAIL="su@${LOGIN}.42.fr"
DEFAULT_USER_EMAIL="user@${LOGIN}.42.fr"
SECRET_LENGTH=32
