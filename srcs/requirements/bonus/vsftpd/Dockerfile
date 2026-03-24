FROM alpine:3.22.3

COPY tools/init.sh /usr/local/bin/init.sh
# COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

RUN apk add --no-cache vsftpd \
        openssl \
        bash \
    && rm -rf /tmp/* /var/cache/apk/* \
    && chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
