#!/bin/sh

set -e

echo "Creating adminer folder at /var/www/html/adminer ..."
mkdir -p /var/www/html/adminer || echo "Failed to create adminer folder"

echo "Downloading adminer ..."
curl -fsSl -o /var/www/html/index.php https://www.adminer.org/latest.php || echo "Failed to download adminer"

echo "Adminer starting ..."
# a cause de nginx et du TLS ca ne marchera pas si on passe pas avec le server php builtin
exec php83 -S 0.0.0.0:8080 -t /var/www/html
