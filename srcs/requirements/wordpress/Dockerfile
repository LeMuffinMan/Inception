FROM alpine:3.22.3

RUN addgroup -g 82 -S www-data || true && \
    addgroup -u 82 -D -S -G www-data www-data|| true

RUN apk add --no-cache \
    wget \
    curl \
    mariadb-client \
    redis \
    php83-fpm \
    php83-tokenizer \
    php83-mysqli \
    php83-xml \
    php83-mbstring \
    php83-curl \
    php83-zip \
    php83-gd \
    php83-intl \
    php83-pecl-imagick \
    php83-cli \
    php83-phar \
    php83-openssl \
    php83-json \
    php83-iconv \
    php83-session && \
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/local/bin/wp

RUN ln -sf /usr/local/bin/php83 /usr/local/bin/php
RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php83/php.ini

RUN mkdir -p /var/www/html

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# COPY conf/wp-config.php /tmp/wp-config.php

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --start-interval=20s --retries=3 \
        CMD php-fpm83 -t || exit 1

ENTRYPOINT ["/usr/local/bin/init.sh"]
