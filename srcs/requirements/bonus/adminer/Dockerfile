FROM alpine:3.22.3

RUN apk add --no-cache \
    curl \
    php83 \
    php83-mysqli \
    php83-session

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
