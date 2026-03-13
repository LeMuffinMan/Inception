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

# until nc -z mariadb 3306; do
#   sleep 2
# done

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

    wp config create \
      --dbname=wordpress \
      --dbuser=wpuser \
      --dbpass=password \
      --dbhost=mariadb:3306 \
      --allow-root

    wp core install \
        --url="https://example.com" \
        --title="My WordPress" \
        --admin_user="admin" \
        --admin_password="adminpass" \
        --admin_email="admin@example.com" \
        --skip-email \
        --allow-root

    wp user create \
        user \
        user@example.com \
        --role=author \
        --user_pass=userpass \
        --allow-root

    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi

exec php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf
