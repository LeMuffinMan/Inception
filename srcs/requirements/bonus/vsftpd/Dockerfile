
FROM alpine:3.22.3

COPY tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache \
    bash \
    vsftpd \
    strace \
    && chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

#ENTRYPOINT ?
CMD ["/usr/local/bin/init.sh"]
