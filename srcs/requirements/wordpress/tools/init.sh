#!/bin/sh

set -e

NC='\033[0m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; GRAY='\033[0;90m'
log_info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
log_debug() { printf "${GRAY}[DEBUG]${NC} %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
# ------------------------------------------------------------------------------

cd /var/www/html/
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

MYSQL_PASSWORD=$(cat /run/secrets/db_password)

WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

log_info "Waiting for MariaDB ..."
TIME=0
until nc -z mariadb 3306; do
    log_info "Waiting for MariaDB ... (${TIME}s)"
    TIME=$((TIME + 1))
    sleep 1
done
log_info "MariaDB is ready"

if [ ! -f /var/www/html/wp-config.php ]; then

    wp core download --allow-root

    log_info "Creating wp-config.php ..."
    wp config create \
      --dbname="${MYSQL_DATABASE}" \
      --dbuser="${MYSQL_USER}" \
      --dbpass="${MYSQL_PASSWORD}" \
      --dbhost=mariadb:3306 \
      --allow-root

    log_info "Installing WordPress ..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${MYSQL_ADMIN_EMAIL}" \
        --allow-root

    log_info "Creating additional user ..."
    wp user create \
        "${WP_USER}" \
        "${MYSQL_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    log_debug "DOMAIN_NAME = $DOMAIN_NAME"

    log_info "Activating Redis cache plugin ..."
    wp plugin install redis-cache --activate --allow-root \
        && log_info "redis-cache installed and activated" \
        || log_warn "Failed to install and activate redis-cache"
    wp config set WP_REDIS_HOST redis --allow-root \
        && log_info "WP_REDIS_HOST set to redis" \
        || log_warn "Failed to set WP_REDIS_HOST"
    wp config set WP_REDIS_PORT 6379 --raw --allow-root \
        && log_info "WP_REDIS_PORT set to 6379" \
        || log_warn "Failed to set WP_REDIS_PORT"
    wp redis enable --allow-root \
        && log_info "redis-cache enabled and configured" \
        || log_warn "Failed to enable redis-cache"

    log_info "WordPress successfully installed"
else
    log_info "WordPress already installed and configured"
fi

sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/' /etc/php83/php-fpm.d/www.conf \
    && log_info "php-fpm socket set to 0.0.0.0:9000" \
    || log_error "Failed to configure php-fpm socket"

exec su -s /bin/sh www-data -c "php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf"
