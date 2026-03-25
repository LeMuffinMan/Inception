
FROM alpine:3.22.3

COPY tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache \
    bash \
    vsftpd \
    && chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

CMD ["/usr/local/bin/init.sh"]
