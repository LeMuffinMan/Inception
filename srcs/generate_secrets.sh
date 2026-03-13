#!/bin/sh

generate_secret() {
    len=${1:-32}
    if command -v openssl > /dev/null 2>&1; then
        openssl rand -base64 "$len" | tr -d '='
    elif [ -r /dev/urandom ]; then
        head -c "$len" /dev/urandom | base64 | tr -d '='
    else
        echo "Error: no random source available"
        return 1
    fi
}

if [ "$1" = "-f" ]; then
    if [ -d secrets ]; then
        read -p "Overide secrets/ ? [y/n] " res
        case "$res" in
            [yY])
                ;;
            *)
                echo "Secrets generation canceled"
                exit 0
                ;;
        esac
    fi
    rm -rf secrets
fi

if [ ! -d secrets/ ]; then
    echo "Generating credentials in secrets: "
    mkdir -p secrets
fi

if [ ! -s secrets/db_password.txt ]; then
    echo "Generating db_passowrd ..."
    echo $(generate_secret 32) > secrets/db_password.txt
fi

if [ ! -s secrets/db_root_password.txt ]; then
    echo "Generating db_root_passowrd ..."
    echo $(generate_secret 32) > secrets/db_root_password.txt
fi

if [ ! -s secrets/mysql_user.txt ]; then
    echo "Generating mysql_user ..."
    echo "mysql_user" > secrets/mysql_user.txt
fi

if [ ! -s secrets/wp_admin_password.txt ]; then
    echo "Generating wp_admin_password..."
    echo $(generate_secret 32) > secrets/wp_admin_password.txt
fi

if [ ! -s secrets/wp_admin_user.txt ]; then
    echo "Generating wp_admin_user..."
    echo $(generate_secret 32) > secrets/wp_admin_user.txt
fi

if [ ! -s secrets/wp_user.txt ]; then
    echo "Generating wp_user..."
    echo wordpress_user > secrets/wp_user.txt
fi

if [ ! -s secrets/wp_user_password.txt ]; then
    echo "Generating wp_user_password..."
    echo $(generate_secret 32) > secrets/wp_user_password.txt
fi
