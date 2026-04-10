#!/bin/bash

# ajouter plus de controles

source "$(dirname "$0")/lib/format.sh"

get_var() {
    local var_name="$1"
    local var_value=""
    while [ -z "$var_value" ]; do
        read -p "$var_name=" var_value
    done
    echo "$var_value"
}

check_env() {
    if [ ! -z "$MYSQL_DATABASE" ]  && \
    [ ! -z "$MYSQL_USER" ] && \
    [ ! -z "$DOMAIN_NAME" ] && \
    [ ! -z "$WP_TITLE" ] && \
    [ ! -z "$WP_USER" ] && \
    [ ! -z "$WP_ADMIN_USER" ] && \
    [ ! -z "$MYSQL_USER" ] && \
    [ ! -z "$MYSQL_USER_EMAIL" ] && \
    [ ! -z "$MYSQL_ADMIN_EMAIL" ]; then
        return 0
    fi
    return 1
    # verifier mails
    # identiques aussi
}

if  [ -r srcs/.env ] || check_env; then
    exit 0
fi

if [ "$1" == "-y" ] && [ -f scripts/auto_generate_env.sh ]; then
    scripts/auto_generate_env.sh
elif [ -f scripts/auto_generate_env.sh ]; then
    read -p "use auto generation env script ? y/n " RES
    if [ $RES == "y" ]; then
        scripts/auto_generate_env.sh
    fi
    exit 0
fi

if [ -f srcs/.env ]; then
    set -a
    if ! source srcs/.env; then
        log_error "Failed sourcing srcs/.env"
        exit 1
    fi
    set +a
    if [ ! -z "$MYSQL_DATABASE" ]  && \
    [ ! -z "$MYSQL_USER" ] && \
    [ ! -z "$DOMAIN_NAME" ] && \
    [ ! -z "$WP_TITLE" ] && \
    [ ! -z "$FTP_USER" ] && \
    [ ! -z "$WP_USER" ] && \
    [ ! -z "$WP_ADMIN_USER" ] && \
    [ ! -z "$MYSQL_USER" ] && \
    [ ! -z "$MYSQL_USER_EMAIL" ] && \
    [ ! -z "$MYSQL_ADMIN_EMAIL" ]; then
        exit 0
    fi
else
    touch "srcs/.env"
fi

log_info "Please fill the following environment variables:"

if [ -z "$MYSQL_DATABASE" ]; then
    MYSQL_DATABASE=$(get_var "MYSQL_DATABASE")
    echo "MYSQL_DATABASE=$MYSQL_DATABASE" >> srcs/.env
fi

if [ -z "$MYSQL_USER" ]; then
    MYSQL_USER=$(get_var "MYSQL_USER")
    echo "MYSQL_USER=$MYSQL_USER" >> srcs/.env
fi

if [ -z "$MYSQL_USER_EMAIL" ]; then
    MYSQL_USER_EMAIL=$(get_var "MYSQL_USER_EMAIL")
    # controler mail
    echo "MYSQL_USER_EMAIL=$MYSQL_USER_EMAIL" >> srcs/.env
fi

while [ -z "$MYSQL_ADMIN_EMAIL" ]; do
    MYSQL_ADMIN_EMAIL=$(get_var "MYSQL_ADMIN_EMAIL")
    # controler mail
    if  [ "$MYSQL_USER_EMAIL" == "$MYSQL_ADMIN_EMAIL" ]; then
        log_warn "That email address is already used — WordPress requires 2 different email addresses"
        MYSQL_ADMIN_EMAIL=""
    else
        echo "MYSQL_ADMIN_EMAIL=$MYSQL_ADMIN_EMAIL" >> srcs/.env
    fi
done

if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$(get_var "DOMAIN_NAME")
    # controler domain name
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> srcs/.env
fi

if [ -z "$WP_TITLE" ]; then
    WP_TITLE=$(get_var "WP_TITLE")
    echo "WP_TITLE=$WP_TITLE" >> srcs/.env
fi

if [ -z "$WP_USER" ]; then
    WP_USER=$(get_var "WP_USER")
    echo "WP_USER=$WP_USER" >> srcs/.env
fi

if [ -z "$WP_ADMIN_USER" ]; then
    WP_ADMIN_USER=$(get_var "WP_ADMIN_USER")
    # controler admin / administrateur
    echo "WP_ADMIN_USER=$WP_ADMIN_USER" >> srcs/.env
fi

if [ -z "$FTP_USER" ]; then
    FTP_USER=$(get_var "FTP_USER")
    echo "FTP_USER=$FTP_USER" >> srcs/.env
fi
