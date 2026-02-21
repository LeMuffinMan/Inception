#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Inception project check"
echo
CONTAINERS=$(docker compose ps)

echo "Mariadb container: "
MARIADB_CONTAINER=$(grep -q "mariadb" $CONTAINERS)
if $MARIADB_CONTAINER; then
    echo "running: ${GREEN}OK${NC}"
    if grep "mariadb" $CONTAINERS | grep -q "unhealthy"; then
        echo "healthy: ${RED}KO${NC}"
    else
        echo "healthy: ${GREEN}OK${NC}"
    fi
else
    echo "running: ${RED}KO${NC}"
fi

#cheker le port
#faire une commande test a mariadb ?
