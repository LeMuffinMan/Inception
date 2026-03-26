#!/bin/sh

set -e

#WORKSTATION ?
cd /var/www/html

# a virer ? : filtrer a la generation
add_domain_if_missing() {
  local var="$1"
  if [[ "$var" != *"@"* ]]; then
    echo "${var}@mail.xx"
  else
    echo "$var"
  fi
}

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
# MYSQL_USER=$(cat /run/secrets/mysql_user)
# MYSQL_ADMIN_EMAIL=$(cat /run/secrets/mysql_admin_email)
# MYSQL_USER_EMAIL=$(cat /run/secrets/mysql_user_email)

WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
# WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
# WP_USER=$(cat /run/secrets/wp_user)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# a vrier
#Wordpress won't accept a not formated email, we use placeholders
MYSQL_ADMIN_EMAIL=$(add_domain_if_missing "$MYSQL_ADMIN_EMAIL")
MYSQL_USER_EMAIL=$(add_domain_if_missing "$MYSQL_USER_EMAIL")

echo "Waiting for MariaDB..."
TIME=0
until mariadb -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for MariaDB...($TIME secs)"
    TIME=$((TIME + 1))
    sleep 1
done
echo "MariaDB is ready"

if [ ! -f /var/www/html/wp-config.php ]; then

    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
      --dbname="${MYSQL_DATABASE}" \
      --dbuser="${MYSQL_USER}" \
      --dbpass="${MYSQL_PASSWORD}" \
      --dbhost=mariadb:3306 \
      --allow-root

    echo "Installing WordPress..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${MYSQL_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WP_USER}" \
        "${MYSQL_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    # wp config set DB_NAME ${MYSQL_DATABASE}
    # wp config set DB_USER ${MYSQL_USER}
    # wp config set DB_PASSWORD ${MYSQL_PASSWORD}

    # cp /tmp/wp-config.php /var/www/html/wp-config.php || echo "Failed to copy wp-config.php"

    echo "Activate Redis cache plugin ..."
    wp plugin install redis-cache --activate --allow-root && echo "install and activate redis successfully" || echo "Failed to install and activate redis-cache"
    wp config set WP_REDIS_HOST redis --allow-root && echo "set WP_REDIS_HOST successfully" || echo "Failed to set WP_REDIS_HOST"
    wp config set WP_REDIS_PORT 6379 --raw --allow-root && echo "set WP_REDIS_PORT to 6379 successfully" || echo "Failed to set WP_REDIS_PORT"
    # wp config set WP_CACHE true --raw --allow-root && "set WP_CACHE true successfully" || echo "Failed to set WP_CACHE true"
    wp redis enable --allow-root && echo "redis-cache enabled and configured successfully" || echo "Failed to enable configured redis-cache"

    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi

sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/' /etc/php83/php-fpm.d/www.conf && echo "socket set OK" || echo "socket set KO"

exec php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf
