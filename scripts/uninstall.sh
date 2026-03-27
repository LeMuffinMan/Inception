#!/bin/bash

echo -e "${YELLOW}Shutting down and removing containers and volumes ...${NC}"
docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
echo -e "${YELLOW}Removing stopped containers ...${NC}"
docker container prune -f

echo -e "${YELLOW}Removing volumes ...${NC}"
docker volume rm srcs_wordpress_data
docker volume rm srcs_mariadb_data
docker volume rm srcs_hugo_data
sudo rm -rf ~/data/mysql && echo -e "${YELLOW}~/data/mysql deleted successfully${NC}"
sudo rm -rf ~/data/wordpress && echo -e "${YELLOW}~/data/wordpress deleted successfully${NC}"
sudo rm -rf ~/data/hugo && echo -e "${YELLOW}~/data/hugo deleted successfully${NC}"
sudo rm -rf ~/data/chessgame && echo -e "${YELLOW}~/data/chessgame deleted successfully${NC}"

echo -e "${YELLOW}Removing dangling images ...${NC}"
docker image prune -f

echo -e "${YELLOW}Removing images ...${NC}"
docker compose -f "$COMPOSE_FILE"  down --rmi all

echo -e "${YELLOW}Cleaning building cache ...${NC}"
docker builder prune -f

echo -e "${YELLOW}Editing /etc/hosts ...${NC}"
sudo sed -i 's/^127\.0\.0\.1\s\+.*/127.0.0.1\tlocalhost/' /etc/hosts
sudo sed -i '/^#\?127\.0\.0\.1/{ /^127\.0\.0\.1\tlocalhost$/!d }' /etc/hosts
sudo cat /etc/hosts

echo -e "${YELLOW}Removing credentials and .env ...${NC}"
rm -rf secrets
rm -rf srcs/.env
