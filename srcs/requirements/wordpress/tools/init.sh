#!/bin/sh

set -e

#WORKSTATION ?
cd /var/www/html/
chown -R www-data:www-data /var/www/html
chown -R 755 /var/www/html
mkdir -p /var/log/php83 && \
touch /var/log/php83/error.log && \
chown -R www-data:www-data /var/log/php83


MYSQL_PASSWORD=$(cat /run/secrets/db_password)

WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

echo "Waiting for MariaDB..."
TIME=0
until nc -z mariadb 3306; do
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
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WP_USER}" \
        "${MYSQL_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "DOMAIN NAME = $DOMAIN_NAME"

    # wp option update home "https://${DOMAIN_NAME}" --allow-root
    # wp option update siteurl "https://${DOMAIN_NAME}" --allow-root

    echo "Activate Redis cache plugin ..."
    wp plugin install redis-cache --activate --allow-root && echo "install and activate redis successfully" || echo "Failed to install and activate redis-cache"
    wp config set WP_REDIS_HOST redis --allow-root && echo "set WP_REDIS_HOST successfully" || echo "Failed to set WP_REDIS_HOST"
    wp config set WP_REDIS_PORT 6379 --raw --allow-root && echo "set WP_REDIS_PORT to 6379 successfully" || echo "Failed to set WP_REDIS_PORT"
    wp redis enable --allow-root && echo "redis-cache enabled and configured successfully" || echo "Failed to enable configured redis-cache"

    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi

sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/' /etc/php83/php-fpm.d/www.conf && echo "socket set OK" || echo "socket set KO"

exec su -s /bin/sh www-data -c "php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf"
