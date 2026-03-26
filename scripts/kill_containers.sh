#!/bin/bash

CONTAINERS=("wordpress" "mariadb" "nginx" "vsftpd" "redis")

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep $container > /dev/null ; then
        docker kill $container > /dev/null
        echo "$container killed"
    fi
done
