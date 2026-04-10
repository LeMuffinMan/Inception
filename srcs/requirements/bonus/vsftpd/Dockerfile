FROM debian:12.13

COPY tools/init.sh /usr/local/bin/init.sh
COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

RUN apt update && apt install -y \
    vsftpd \
    tini \
    && mkdir -p /var/run/vsftpd/empty \
    && chmod 555 /var/run/vsftpd/empty \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /usr/local/bin/init.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/init.sh"]
