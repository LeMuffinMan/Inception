FROM alpine:3.22.3

COPY tools/init.sh /usr/local/bin/init.sh
# virer les dependances en trop
RUN apk add --no-cache \
        wget \
        mariadb-client \
        php83-redis \
        php83-fpm \
        php83-tokenizer \
        php83-mysqli \
        php83-xml \
        php83-mbstring \
        php83-zip \
        php83-ctype \
        # php83-gd \
        # php83-intl \
        php83-pecl-imagick \
        php83-cli \
        php83-phar \
        php83-openssl \
        php83-json \
        php83-iconv \
        php83-session && \
    wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp && \
    addgroup -g 82 -S www-data || true && \
    addgroup -u 82 -D -S -G www-data www-data|| true && \
    # mv wp-cli.phar /usr/local/bin/wp && \
    # ln -sf /usr/local/bin/php83 /usr/local/bin/php && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php83/php.ini && \
    mkdir -p /var/www/html && \
    chmod +x /usr/local/bin/init.sh && \
    rm -rf /tmp/* /var/cache/apk/*

# COPY conf/wp-config.php /tmp/wp-config.php

EXPOSE 9000

# HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --start-interval=20s --retries=3 \
#         CMD php-fpm83 -t || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
