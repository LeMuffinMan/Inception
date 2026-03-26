#!/bin/bash

get_var() {
    local var_name="$1"
    local var_value=""
    while [ -z "$var_value" ]; do
        read -p "$var_name=" var_value
    done
    echo "$var_value"
}

if [ ! -z "$MYSQL_DATABASE" ]  && \
[ ! -z "$MYSQL_USER" ] && \
[ ! -z "$DOMAIN_NAME" ] && \
[ ! -z "$WP_TITLE" ] && \
[ ! -z "$WP_USER" ]; then
    exit 0
fi

if [ -f srcs/.env ]; then
    set -a
    if ! source srcs/.env; then
        echo "Failed sourcing srcs/.env"
        exit 1
    fi
    set +a
    if [ ! -z "$MYSQL_DATABASE" ]  && \
    [ ! -z "$MYSQL_USER" ] && \
    [ ! -z "$DOMAIN_NAME" ] && \
    [ ! -z "$WP_TITLE" ] && \
    [ ! -z "$FTP_USER" ] && \
    [ ! -z "$WP_USER" ]; then
        exit 0
    fi
else
    touch "srcs/.env"
fi

echo "Please, fill the following environment variables:"

if [ -z "$MYSQL_DATABASE" ]; then
    MYSQL_DATABASE=$(get_var "MYSQL_DATABASE")
    echo "MYSQL_DATABASE=$MYSQL_DATABASE" >> srcs/.env
fi

if [ -z "$MYSQL_USER" ]; then
    MYSQL_USER=$(get_var "MYSQL_USER")
    echo "MYSQL_USER=$MYSQL_USER" >> srcs/.env
fi

if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$(get_var "DOMAIN_NAME")
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> srcs/.env
fi

if [ -z "$WP_TITLE" ]; then
    WP_TITLE=$(get_var "WP_TITLE")
    echo "WP_TITLE=$WP_TITLE" >> srcs/.env
fi

if [ -z "$FTP_USER" ]; then
    FTP_USER=$(get_var "FTP_USER")
    echo "FTP_USER=$FTP_USER" >> srcs/.env
fi

if [ -z "$WP_USER" ]; then
    WP_USER=$(get_var "WP_USER")
    echo "WP_USER=$WP_USER" >> srcs/.env
fi

# pour les mail on ajoute un ctrl
