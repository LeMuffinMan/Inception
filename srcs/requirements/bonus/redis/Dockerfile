FROM alpine:3.22.3

# COPY conf/redis.conf /etc/redis.conf
# COPY tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache \
        redis \
    # && chmod +x /usr/local/bin/init.sh \
    && rm -rf /tmp/* /var/cache/apk/*

EXPOSE 6379

CMD ["redis-server", "--protected-mode", "no", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
