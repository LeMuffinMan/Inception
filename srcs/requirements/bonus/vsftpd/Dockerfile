
FROM debian:13.3

COPY tools/init.sh /usr/local/bin/init.sh
COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

RUN apt update && apt install -y \
    vsftpd \
    iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/init.sh"]
