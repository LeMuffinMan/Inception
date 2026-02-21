#!/bin/sh
# set -e

# We want to install and setup the database, only if it does not exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    rm -rf /var/lib/mysql/*

	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	# We start mariadb only to configure it. We want to prevent any external access, since to the db is not configured and since root has no password yet,
	# -skip-networking prevents port 3306 to enable and allow extern access during the db configuration
	/usr/bin/mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &

    # until == !while
    # SELECT 1 is the simpliest request in SQL : it returns 1 without editing any table. It's a ping, we don't need the value returned, only the success / failure of the request
    # As long as this request fails, we want to wait for the db to be fully started
	until mariadb -u root --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1; do
	    sleep 1
	done

    # for following lines, refer to .env to provide your own variables if needed
	# we must configure a root password
	mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY'${MYSQL_ROOT_PASSWORD}';"

    # We create the database itself
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

    # We create a wordpress user
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    # Now we set the user as admin
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"

	# Now we apply our privileges change
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

	#Since we configured mariadb, we want to shut it down, so exec at the end of this script will use the process executing this script, as the one executing the mariadb
	mariadb-admin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

	#we could also do mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHUTDWON;", but mariadb-admin is meant for such operation
fi

#in any case, we want the process executing this script as entrypoint for the container, to execute and handle mariadb now. It must keep running
#In a container, the execution of the entrypoint /init.sh makes this process PID 1 (which is normally /sbin/init, the parent of all other process)
#using exec, we replace PID 1 = /init.sh to PID 1 = /usr/bin/mariadb, thus, there is only one PID running in our container, it runs mariadb.
exec /usr/bin/mariadbd  --user=mysql --datadir=/var/lib/mysql

#doc :
# mariadb -u root <=> en tant que root
# mariadb -u root -p"${VAR}" <=> needs a root password, -p allows us to give it in one command

# les ` sont importants pour la syntaxe SQL (delimite des identifiants), mais interpretes par le shell, donc on doit les escape avec \
