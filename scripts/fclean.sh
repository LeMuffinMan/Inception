#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "You must have sudo privilege to use make fclean, to perform following operations:
        - Deletion of ~/data/mysql and ~/data/wordpress require sudo since they are owned by their respective user
        - Edit /etc/hosts to undo the redirection of 127.0.0.1 to your domain name instead of localhost"
    echo "If you didn't setup this project yourself, please contact an administrator"
    exit 1
fi

source "$(dirname "$0")/lib/format.sh"
COMPOSE_FILE="srcs/docker-compose.yml"

echo -e "${YELLOW}Full cleaning ...${NC}"
echo -e "${YELLOW}Shutting down and removing containers and volumes ...${NC}"
docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
echo -e "${YELLOW}Cleaning stopped containers ...${NC}"
docker container prune -f
echo -e "${YELLOW}Cleaning volumes ...${NC}"
sudo rm -rf ~/data/mysql && echo -e "${YELLOW}~/data/mysql deleted successfully${NC}"
sudo rm -rf ~/data/wordpress && echo -e "${YELLOW}~/data/wordpress deleted successfully${NC}"
echo -e "${YELLOW}Cleaning dangling images ...${NC}"
docker image prune -f
echo -e "${YELLOW}Cleaning building cache ...${NC}"
docker builder prune -f
echo -e "${YELLOW}Removing images ...${NC}"
docker compose -f "$COMPOSE_FILE"  down --rmi all
# rm -rf secrets
# rm -rf srcs/.env

echo -e "${YELLOW}Editing /etc/hosts ..."
sed -i 's/^127.0.0.1//g' /etc/hosts
sed -i 's/^#127.0.0.1/127.0.0.1\tlocalhost/g' /etc/hosts
