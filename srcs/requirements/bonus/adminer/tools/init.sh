#!/bin/sh

set -e

echo "Creating adminer folder at /var/www/html/adminer ..."
mkdir -p /var/www/html/adminer || echo "Failed to create adminer folder"

echo "Downloading adminer ..."
curl -fsSl -o /var/www/html/adminer.php https://www.adminer.org/latest.php || echo "Failed to download adminer"

chown -R $(whoami):$(whoami) /var/www/html/adminer

if [ -f /etc/php83/php-fpm.d/www.conf ]; then
    echo "binding socket to listen on any interface on port 8080 ..."
    sed -i 's/^listen =  .*/listen = 0.0.0.0:8080/' /etc/php83/php-fpm.d/www.conf || echo "Failed to edit /etc/php83/php-fpm/www.conf"
fi

echo "Adminer starting ..."
exec php-fpm83 -F
