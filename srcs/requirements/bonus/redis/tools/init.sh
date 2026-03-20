#!/bin/sh

mkdir -p /data

redis-server /etc/redis.conf "--daemonize no" "--protected-mode no"
