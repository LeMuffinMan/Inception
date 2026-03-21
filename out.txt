FROM alpine:3.21 AS builder

RUN apk add --no-cache wget

RUN wget -O adminer.php https://www.adminer.org/latest.php

FROM alpine:3.21

RUN apk add --no-cache \
	php \
	php-mysqli \
	php-session

WORKDIR /var/www

COPY --from=builder /adminer.php .

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "adminer.php"]
