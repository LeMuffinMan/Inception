FROM alpine:3.22.3

RUN apk add --no-cache redis

# COPY conf/redis.conf /etc/redis.conf
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 6379

HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --start-interval=20s --retries=3 \
        CMD redis-cli ping | grep -q  PONG || exit 1

ENTRYPOINT [ "/usr/local/bin/init.sh" ]
