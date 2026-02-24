
COMPOSE_FILE=srcs/docker-compose.yml
COMPOSE=docker compose -f $(COMPOSE_FILE)
CHECK_SCRIPT=srcs/check_inception.sh


all: up check

up:
	@echo "Starting containers ..."
	$(COMPOSE) up -d --build

down:
	@echo "Shutting down containers ..."
	$(COMPOSE) down

clean:
	@echo "Cleaning containers and volumes ..."
	$(COMPOSE) down -v

fclean: clean
	@echo "Full cleaning ..."
	@echo "Shutting down and removing containers and volumes ..."
	$(COMPOSE) down --volumes --remove-orphans
	@echo "Cleaning stopped containers ..."
	docker container prune -f > /dev/null
	@echo "Cleaning dangling images ..."
	docker image prune -f > /dev/null
	@echo "Cleaning building cache ..."
	docker builder prune -f > /dev/null
	@echo "Removing images ..."
	$(COMPOSE) down --rmi all

re:  fclean up check

check:
	$(CHECK_SCRIPT)

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

.PHONY: up down re clean check fclean logs status
