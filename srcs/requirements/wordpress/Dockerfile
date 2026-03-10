FROM alpine:3.22.3

# RUN add group -g 82 -S www-data || true && \
#     add group -u 82 -D -S -G www-data www-data|| true

RUN apk add --no-cache \
    curl \
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
    mysql-client
    # redis

RUN mkdir -p /var/www/html

COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh
# COPY conf

EXPOSE 9000

# HEALTHCHECK

ENTRYPOINT ["/usr/bin/init.sh"]
