
COMPOSE_FILE=srcs/docker-compose.yml
COMPOSE=docker compose -f $(COMPOSE_FILE)
CHECK_SCRIPT=scripts/check_inception.sh
CRASH_SCRIPT=scripts/crash_test.sh
VOLUME_SCRIPT=scripts/volumes_check.sh


all: up check

up:
	srcs/generate_secrets.sh
	mkdir -p ~/data/mysql
	mkdir -p ~/data/wordpress
	@echo "Starting containers ..."
	$(COMPOSE) up -d --build --no-recreate

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
	@echo "Cleaning volumes ..."
	sudo rm -rf ~/data/mysql
	sudo rm -rf ~/data/wordpress
	@echo "Cleaning dangling images ..."
	docker image prune -f > /dev/null
	@echo "Cleaning building cache ..."
	docker builder prune -f > /dev/null
	@echo "Removing images ..."
	$(COMPOSE) down --rmi all
	rm -rf secrets

re:  fclean up check

check:
	$(CHECK_SCRIPT)

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

crash:
	$(CRASH_SCRIPT)
	$(CHECK_SCRIPT)

volume:
	$(VOLUME_SCRIPT)
	$(CHECK_SCRIPT)

checks:
	$(VOLUME_SCRIPT)
	$(CRASH_SCRIPT)
	$(CHECK_SCRIPT)

secrets:
	srcs/generate_secrets.sh -f

.PHONY: up down re clean check fclean logs status crash secrets volume checks
