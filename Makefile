
COMPOSE= docker compose -f srcs/docker-compose.yml

all: up

	#empecher un rebuild si deja build ?
	# ne pas recreer les volumes si ils existent deja
up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	$(COMPOSE) down --rmi all

re:  down up

check:
	srcs/check_inception.sh

.PHONY: up down re clean check fclean
