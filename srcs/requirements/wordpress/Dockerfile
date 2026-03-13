FROM alpine:3.22.3

RUN addgroup -g 82 -S www-data || true && \
    addgroup -u 82 -D -S -G www-data www-data|| true

RUN apk add --no-cache \
    wget \
    curl \
    mysql-client \
    redis \
    php83-fpm \
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
    php83-session \
    php83-session && \
    # DL the wp CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/bin/wp #tout mettre dans /usr/local/bin !!
    # redis

RUN mkdir -p /var/www/html

COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --start-interval=20s --retries=3 \
        CMD php-fpm83 -t || exit 1

#tout mettre dasn /usr/local/bin
ENTRYPOINT ["/usr/bin/init.sh"]
