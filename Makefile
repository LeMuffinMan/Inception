
COMPOSE= docker compose -f srcs/docker-compose.yml

all: up

up:
	$(COMPOSE) up -d --build
	srcs/check_inception.sh

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

clean-containers:
	docker container prune

fclean: clean
	docker container prune -f
	$(COMPOSE) down --rmi all
	# docker system prune -f  # generaliser ?

re:  fclean up

check:
	srcs/check_inception.sh

.PHONY: up down re clean check fclean
