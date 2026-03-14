#!/bin/sh

set -e

# checker docker secrets
# export WORDPRESS_ADMIN_USER=$(cat /run/secrets/wordpress_admin_user)
# export WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
# export WORDPRESS_USER=$(cat /run/secrets/wordpress_user)
# export WORDPRESS_PASSWORD=$(cat /run/secrets/wordpress_password)
# export MYSQL_USER=$(cat /run/secrets/mysql_user)
# export MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
# export WORDPRESS_EMAIL=$(cat /run/secrets/wordpress_email)

cd /var/www/html

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_USER=$(cat /run/secrets/mysql_user)
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WORDPRESS_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WORDPRESS_USER=$(cat /run/secrets/wp_user)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

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
      --dbname=wordpress \
      --dbuser=${MYSQL_USER} \
      --dbpass=${MYSQL_PASSWORD} \
      --dbhost=mariadb:3306 \
      --allow-root

    echo "Installing WordPress..."
    #changer le domain name ici avec une variable d'enviuronnement et choper dans .env
    # idem pour title
    # faire un secret en plus pour email ?
    wp core install \
        --url="https://example.com" \
        --title="My WordPress" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="admin@example.com" \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WORDPRESS_USER}" \
        user@example.com \
        --role=author \
        --user_pass="$WORDPRESS_USER_PASSWORD}" \
        --allow-root

    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi

exec php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf
