#!/bin/sh

mariadb --user=mysql & #--socket=/run/mysqld/mysqld.sock

sleep 5

mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

mariadb -u root -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'IDENTIFIED BY ${MYSQL_PASSWORD}';"
mariadb -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mariadb -u root -e "FLUSH PRIVILEGES;"

exec mariadb --user=mysql
