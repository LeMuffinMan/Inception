FROM alpine:latest

RUN apk add --no-cache mariadb mariadb-client
RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld
RUN chmod 777 /run/mysqld

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 3306

USER mysql

ENTRYPOINT ["/init.sh"]
