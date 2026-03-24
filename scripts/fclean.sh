#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "You must have sudo privilege to clean this project, to perform following operations:
        - Deletion of ~/data/mysql and ~/data/wordpress require sudo since they are owned by their respective user
        - Edit /etc/hosts to undo the redirection of 127.0.0.1 to your domain name instead of localhost"
    echo "If you didn't setup this project yourself, please contact an administrator"
    exit 1
fi

source "$(dirname "$0")/lib/format.sh"
COMPOSE_FILE="srcs/docker-compose.yml"

echo -e "${NC}Full cleaning ...${GREY}"
echo -e "${NC}Shutting down and removing containers and volumes ...${GREY}"
docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
echo -e "${NC}Cleaning stopped containers ...${GREY}"
docker container prune -f
echo -e "${NC}Cleaning volumes ...${GREY}"
sudo rm -rf ~/data/mysql
sudo rm -rf ~/data/wordpress
echo -e "${NC}Cleaning dangling images ...${GREY}"
docker image prune -f
echo -e "${NC}Cleaning building cache ...${GREY}"
docker builder prune -f
echo -e "${NC}Removing images ...${GREY}"
docker compose -f "$COMPOSE_FILE"  down --rmi all
# rm -rf secrets
# rm -rf srcs/.env
