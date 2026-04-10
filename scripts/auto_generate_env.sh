#!/bin/bash

echo "MYSQL_DATABASE=${USER}_db
MYSQL_USER=${USER}_mysql_user
MYSQL_USER_EMAIL=${USER}@mail.fr
MYSQL_ADMIN_EMAIL=${USER}_su@mail.fr
DOMAIN_NAME=${USER}.42.fr
WP_TITLE=${USER}_wordpress
WP_USER=${USER}_wordpress_user
WP_ADMIN_USER=${USER}_wordpress_su
FTP_USER=$USER" > srcs/.env
