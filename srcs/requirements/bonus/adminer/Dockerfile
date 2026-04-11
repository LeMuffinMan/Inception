FROM alpine:3.22.3
WORKDIR /var/www
RUN apk add --no-cache \
        php \
        php-mysqli \
        php-session \
        wget \
    && wget -O adminer.php https://www.adminer.org/latest.php \
    && echo '<?php require "/var/www/adminer.php";' > index.php
EXPOSE 8080
ENTRYPOINT ["php", "-S", "0.0.0.0:8080"]
