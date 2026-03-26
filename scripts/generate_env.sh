#!/bin/bash

get_var() {
    local var_name="$1"
    local var_value=""
    while [ -z "$var_value" ]; do
        read -p "$var_name=" var_value
    done
    echo "$var_value"
}

if [ -f srcs/.env ]; then
    set -a
    source srcs/.env || echo "Failed sourcing srcs/.env"; exit 1
    set +a
    if [ ! -z "$MYSQL_DATABASE" ]  && [ ! -z "$MYSQL_USER" ] && [ ! -z "$DOMAIN_NAME" ] && [ ! -z "$WP_TITLE" ]; then
        exit 0
    fi
else
    touch "srcs/.env"
fi

echo "Please, fill the following environment variables:"

if [ -z "$MYSQL_DATABASE" ]; then
    MYSQL_DATABASE=$(get_var "MYSQL_DATABASE")
fi

if [ -z "$MYSQL_USER" ]; then
    MYSQL_USER=$(get_var "MYSQL_USER")
fi

if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$(get_var "DOMAIN_NAME")
fi

if [ -z "$WP_TITLE" ]; then
    WP_TITLE=$(get_var "WP_TITLE")
fi

# pour les mail on ajoute un ctrl
