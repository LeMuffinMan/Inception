#!/bin/bash

# le commentaire a deplacer dans un README pour Redis

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"
RES=""
section "Host configuration"

if ! grep -qE "^127\.0\.0\.1[[:blank:]]+${DOMAIN}([[:blank:]]|$)" /etc/hosts; then
    read -p "Confirm edit /etc/hosts to redirect localhost to $DOMAIN ? y/n " RES
    if [ $RES == "y" ]; then
        sudo sed -i "/^127\.0\.0\.1[[:space:]]\+localhost/{
            s/^/#/
            a 127.0.0.1\t$DOMAIN
        }" /etc/hosts
    fi
fi

# Allows the kernel to allocate memory even if there’s no
# guarantee that the memory will be available when the
# program tries to use it.
# This is needed to redis to work correctly as it use specific cache data strucutres
# relying on kernel memory management
#
# setting it to 1 will not be persistent after reboot
# to make it persistent edit /etc/sysctl.conf and append to it : vm.overcommit_memory=1
RES=""
if sysctl vm.overcommit_memory | grep "vm.overcommit_memory = 0" > /dev/null; then
    read -p "Confirm to enable memory overcommit (required for Redis-cache) y/n " RES
    if [ $RES == "y" ]; then
        sudo sysctl vm.overcommit_memory=1
    fi
fi

echo
