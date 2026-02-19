FROM alpine:latest

RUN apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql
RUN mkdir -p /run/mysql && chown -R mysql:mysql /run/mysql
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

#virer les variables par defaut ?
# ENV MYSQL_DATABASE=wordpress
# ENV MYSQL_USER=wp_user
# ENV MYSQL_PASSWORD=secret
# ENV MYSQL_ROOT_PASSWORD=rootsecret

EXPOSE 3306

CMD ["sh", "/init.sh"]

# CMD ["mysqld_safe", "--user=mysql", "--socket=/run/mysqld/mysqld.sock"]
