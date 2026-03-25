FROM alpine:3.22.3

COPY conf/nginx.conf /etc/nginx/http.d/nginx.conf
COPY tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache \
    nginx \
    openssl && \
    rm -rf /etc/nginx/http.d/default.conf && \
    chmod +x /usr/local/bin/init.sh

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
