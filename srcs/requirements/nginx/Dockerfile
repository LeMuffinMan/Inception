FROM alpine:3.22.3

#To remove !!!
COPY tools/index.html /usr/share/nginx/html/index.html

COPY tools/conf /etc/nginx/http.d/nginx.conf
COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh

RUN apk add --no-cache \
    nginx \
    openssl && \
    rm -rf /etc/nginx/http.d/default.conf

EXPOSE 443

ENTRYPOINT [ "/usr/bin/init.sh" ]

#pour lancer sans https sur 8080
# docker build -t my-nginx-no-ssl . && docker run -d -p 8080:80 --name nginx my-nginx-no-ssl:latest
