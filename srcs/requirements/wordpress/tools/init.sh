#!/bin/sh

set -e

cd /var/www/html

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_USER=$(cat /run/secrets/mysql_user)
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WORDPRESS_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WORDPRESS_USER=$(cat /run/secrets/wp_user)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
MYSQL_ADMIN_EMAIL=$(cat /run/secrets/mysql_admin_email)
MYSQL_USER_EMAIL=$(cat /run/secrets/mysql_user_email)

echo "Waiting for MariaDB..."
TIME=0
until mariadb -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for MariaDB...($TIME secs)"
    TIME=$((TIME + 1))
    sleep 1
done
echo "MariaDB is ready"

if [ ! -f /var/www/html/wp-config.php ]; then

    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
      --dbname="${MYSQL_DATABASE}" \
      --dbuser="${MYSQL_USER}" \
      --dbpass="${MYSQL_PASSWORD}" \
      --dbhost=mariadb:3306 \
      --allow-root

    echo "Installing WordPress..."
    #changer le domain name ici avec une variable d'enviuronnement et choper dans .env
    # idem pour title
    # faire un secret en plus pour email ?
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${MYSQL_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WORDPRESS_USER}" \
        "${MYSQL_USER_EMAIL}" \
        --role=author \
        --user_pass="$WORDPRESS_USER_PASSWORD}" \
        --allow-root

    if ! wp post list --post_type=post --name="static-page" --allow-root | grep -q "static-page"; then
        wp post create \
            --post_title="Ma page statique" \
            --post_content="$(cat /path/to/page.html)" \
            --post_status=publish \
            --post_name="static-page" \
            --post_type=page \
            --allow-root

    fi
    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi

sed -i 's/listen = 127.0.0.1/listen = 0.0.0.0:9000/' /etc/php83/php-fpm.d/www.conf && echo "socket set OK" || echo "socket set KO"

exec php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf
