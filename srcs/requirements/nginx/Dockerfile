FROM alpine:3.22.3

RUN apk add --no-cache \
    nginx \
    openssl && \
    rm -rf /etc/nginx/http.d/default.conf

COPY conf/nginx.conf /etc/nginx/http.d/nginx.conf
COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

EXPOSE 443

ENTRYPOINT [ "/usr/bin/init.sh" ]
