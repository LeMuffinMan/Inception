
all: up
	srcs/check_inception.sh

up:
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down -v --no-orphans

re:  down up

# clean

# fclean
