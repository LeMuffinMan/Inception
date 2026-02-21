#!/bin/sh

# We want to install and setup the database, only if it does not exist

if [ ! -d "/var/lib/mysql" ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	#we start mariadb only to configure it
	/usr/bin/mariadbd-safe --datadir=/var/lib/mysql &

	sleep 5

    # for following lines, refer to .env to provid your own variables if needed
	# we must configure a root password
	mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY'${MYSQL_ROOT_PASSWORD}';"

    # We create the database itself
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \${MYSQL_DATABASE}\;"

    # We create a wordpress user
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    # Now we set the user as admin
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_USER}'@'%' IDENTIFED BY '${MYSQL_PASSWORD}';"

	# Now we apply our privileges change
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

	#Since we configured mariadb, we want to shut it down, so exec at the end of this script will use the process executing this script, as the one executing the mariadb
	mariadb-admin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

	#we could also do mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHUTDWON;", but mariadb-admin is meant for such operation
fi

exec /usr/bin/mariadbd-safe --datadir=/var/lib/mysql

#doc :
# mariadb -u root <=> en tant que root
# mariadb -u root -p"${VAR}" <=> needs a root password, -p allows us to give it in one command
