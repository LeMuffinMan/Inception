
all: up
	srcs/check_inception.sh

up:
	#empecher un rebuild si deja build ?
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down -v --no-orphans
	#virer les volumes

re:  down up

# clean

# fclean
