#!/bin/sh

mkdir -p /data

echo "maxmemory 256mb" >> /etc/redis.conf
echo "maxmemory-policy allkeys-lru" >> /etc/redis.conf
sed -i -r "s/bind 127.0.0.1/bind 0.0.0.0/" /etc/redis.conf

redis-server /etc/redis.conf "--daemonize no" "--protected-mode no" || echo "Failed to exec redis"
