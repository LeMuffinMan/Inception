FROM alpine:3.22.3

COPY tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache vsftpd \
        openssl \
        bash \
        sudo \
    && chmod +x /usr/local/bin/init.sh \
    && rm -rf /tmp/* /var/cache/apk/*

EXPOSE 21 21100-21110

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
