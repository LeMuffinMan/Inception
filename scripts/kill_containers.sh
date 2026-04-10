#!/bin/bash

# sourcer config pour recuperer les containers ?
CONTAINERS=("wordpress" "mariadb" "nginx" "vsftpd" "redis" "adminer")

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep $container > /dev/null ; then
        docker kill $container > /dev/null
        echo "$container killed"
    fi
done
