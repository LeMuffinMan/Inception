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

# wordpress taking usually arround 20 secs to start, choosing a lower timeout length
# could invalid some tests
WAIT_TIMEOUT=45
RESTART_TIMEOUT=45

#Add in this array all credentials files you need to generate. It will be randomly generated to prevent leaking secrets
CREDENTIALS_FILES=("db_password.txt" "db_root_password.txt" "wp_admin_password.txt" "wp_user_password.txt" "ftp_pass.txt")

# to customize your own mariadb/wordpress setup, edit theses variables
# DEFAULT_MYSQL_USER="mysql_user"
# DEFAULT_WP_ADMIN_USER="wp_su_${LOGIN}"
# DEFAULT_WP_USER="wp_user_${LOGIN}"
# DEFAULT_ADMIN_EMAIL="su@${LOGIN}.42.fr"
# DEFAULT_USER_EMAIL="user@${LOGIN}.42.fr"
# DEFAULT_FTP_USER="ftp_user"

#Each service must have his container, named as the service
# Feel free to add a new service, adding a new CONTAINER variablem and add it in the variable
# CONTAINERS_TO_TEST if you want it to be waited and checked
CONTAINER_MARIADB="mariadb"
CONTAINER_NGINX="nginx"
CONTAINER_WORDPRESS="wordpress"
CONTAINER_REDIS="redis"
CONTAINER_ADMINER="adminer"
CONTAINER_FTP="vsftp"
# CONTAINER_YOUR_SERVICE="your_service"
# ADD in this array your new container to integrate it as a container to wait or to crash test
CONTAINERS_TO_TEST=("$CONTAINER_REDIS" "$CONTAINER_WORDPRESS" "$CONTAINER_NGINX" "$CONTAINER_MARIADB" "$CONTAINER_ADMINER" "$CONTAINER_FTP")

# by default, because of the subject requirements, your volumes named <service>_data will be prefixed with srcs_ because
# its in the folder srcs ... these lines are used to grep your volumes, so change it following your setup
VOLUME_MARIADB="srcs_mariadb_data"
VOLUME_WORDPRESS="srcs_wordpress_data"

# we need at least two volumes and their persistancy for the mandatory PORT_MARIADB_EXPECTED
# for the bonus part, we add the adminer volume too
VOLUMES_TO_CHECK=("mariadb" "wordpress")
VOLUME_HOST_PATH_PATTERN="/home/.*/data"

# Theses variables are set to respect the tree example provided in the subject.
ROOT_DIR="$(dirname "$0")/.."
COMPOSE_FILE="${ROOT_DIR}/srcs/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/srcs/.env"
SECRETS_DIR="${ROOT_DIR}/secrets"
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
REQUIRED_ENV_VARS=("DOMAIN_NAME" "MYSQL_USER" "MYSQL_DATABASE")
ADMIN_FORBIDDEN_PATTERN="^admin$|admin-|^administrator$"
