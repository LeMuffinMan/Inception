FROM alpine:3.22.3

# COPY before for cache perfomance, and layers optimisations
COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

RUN apk add --no-cache mariadb mariadb-client && rm -rf /var/lib/mysql \
    && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql \
    && mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

EXPOSE 3306

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD healthcheck.sh --connect --innodb_initialized || exit 1

ENTRYPOINT ["/usr/bin/init.sh"]
