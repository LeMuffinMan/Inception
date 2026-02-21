FROM alpine:latest

RUN apk add --no-cache mariadb mariadb-client && rm -rf /var/lib/mysql
RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 3306

# ajouter un healthcheck ?

# USER mysql

ENTRYPOINT ["/init.sh"]
