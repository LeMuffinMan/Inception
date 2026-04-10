#!/bin/sh

set -e

# --- Colors & log functions ---------------------------------------------------
NC='\033[0m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; GRAY='\033[0;90m'
log_info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
# ------------------------------------------------------------------------------

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    rm -rf /var/lib/mysql/*

    log_info "MariaDB installation ..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    log_info "Starting MariaDB ..."
	# We start mariadb only to configure it. We want to prevent any external access, since to the db is not configured and since root has no password yet,
	# -skip-networking prevents port 3306 to enable and allow extern access during the db configuration
	/usr/bin/mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &

	until mariadb -u root --connect-timeout=2 -e "SELECT 1" > /dev/null 2>&1; do
	    log_info "Waiting for MariaDB to be ready ..."
	    sleep 1
	done

	log_info "MariaDB is running, starting configuration ..."

	# configure root password
	mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY'${MYSQL_ROOT_PASSWORD}';" && log_info "Root password configured"

    # We create the database itself
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;" && log_info "Database created"

    # We create a wordpress user
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" && log_info "User $MYSQL_USER created"

    # Now we set the user as admin
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" && log_info "User $MYSQL_USER granted admin privileges"

	# Now we apply our privileges change
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;" && log_info "Privileges flushed"

	#Since we configured mariadb, we want to shut it down, so exec at the end of this script will use the process executing this script, as the one executing the mariadb
	mariadb-admin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown && log_info "MariaDB successfully configured"
fi

#in any case, we want the process executing this script as entrypoint for the container, to execute and handle mariadb now. It must keep running
#In a container, the execution of the entrypoint /init.sh makes this process PID 1 (which is normally /sbin/init, the parent of all other process)
#using exec, we replace PID 1 = /init.sh to PID 1 = /usr/bin/mariadb, thus, there is only one PID running in our container, it runs mariadb.
exec /usr/bin/mariadbd  --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306 --skip-networking=0
