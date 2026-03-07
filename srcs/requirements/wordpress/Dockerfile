FROM alpine:3.22.3

# RUN add group -g 82 -S www-data || true && \
#     add group -u 82 -D -S -G www-data www-data|| true

RUN apk add --no-cache \
    curl \
    # wget \
    mysql-client \
    # redis
    # php83 \
    #
   # curl
   # chmod
   # mv

RUN mkdir -p /var/www/html

COPY tools/init.sh /usr/bin/init.sh
RUN chmod +x /usr/bin/init.sh
# COPY conf

EXPOSE 9000

# HEALTHCHECK

ENTRYPOINT ["/usr/bin/init.sh"]
