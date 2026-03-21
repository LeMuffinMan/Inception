FROM alpine:3.22.3

RUN apk add --no-cache vsftpd

COPY conf/vsftpd.conf /etc/vsftpd.conf

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
