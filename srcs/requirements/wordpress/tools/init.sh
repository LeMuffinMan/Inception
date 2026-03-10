#!/bin/sh

# Recuperer les variables d'environnement

cd /var/www/html

if [ ! -f /var/www/html/wp-config.php ]; then
# curl une config
# la modifier et la configurer avec les var d'env
#
# Salts ?
#
# Perm on volumes
#
# installation of the website
#
# Gerer redis ici
#
# Encore les perms ?
#
#
    echo "Wordpress successfully installed"
else
    echo "Wordpress already installed and configured"
fi


#setup port on socket

# start wordpress with php

exec php-fpm83 --nodaemonize --fpm-config /etc/php83/php-fpm.conf
