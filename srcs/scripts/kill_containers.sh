#!/bin/bash

source "$(dirname "$0")/lib/format.sh"

for container in "${CONTAINERS_TO_TEST[@]}"; do
    if docker ps | grep $container > /dev/null ; then
        docker kill $container > /dev/null
        log_info "$container killed"
    fi
done
