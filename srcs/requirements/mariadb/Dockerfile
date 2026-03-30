FROM alpine:3.22.3

COPY --chmod=755 tools/init.sh /usr/local/bin/init.sh
COPY --chmod=755 tools/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN apk add --no-cache mariadb mariadb-client && rm -rf /var/lib/mysql \
    && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql \
    && mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
