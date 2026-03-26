COMPOSE_FILE=srcs/docker-compose.yml
COMPOSE=docker compose -f $(COMPOSE_FILE)
CHECK_SCRIPT=scripts/check_inception.sh
CRASH_SCRIPT=scripts/crash_test.sh
VOLUME_SCRIPT=scripts/volumes_check.sh
SECRET_GEN_SCRIPT=scripts/generate_secrets.sh
ENV_GEN_SCRIPT=scripts/generate_env.sh
CLEAN_SCRIPT=scripts/fclean.sh
UNINSTALL_SCRIPT=scripts/uninstall.sh
KILL_SCRIPT=scripts/kill_containers.sh

all: up check

up:
	$(ENV_GEN_SCRIPT)
	$(SECRET_GEN_SCRIPT)
	@echo "Creating folders for persistent storage ..."
	mkdir -p ~/data/mysql
	mkdir -p ~/data/wordpress
	@echo "Starting containers ..."
	$(COMPOSE) up -d --build --no-recreate

down:
	@echo "Shutting down containers ..."
	$(COMPOSE) down

clean:
	@echo "\033[0;33mStoping and deleting all containers ...\033[0m"
	$(COMPOSE) down -v

fclean: clean
	$(CLEAN_SCRIPT)

re:
	$(KILL_SCRIPT)
	$(clean_script)
	$(MAKE) up
	$(MAKE) check

check:
	$(CHECK_SCRIPT) $(or $(SERVICE),)

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

crash:
	$(CRASH_SCRIPT)

volume:
	$(VOLUME_SCRIPT)

checks:
	$(VOLUME_SCRIPT)
	$(CRASH_SCRIPT)
	$(CHECK_SCRIPT)

regen:
	#rm -rf srcs/.env
	$(SECRET_GEN_SCRIPT) -f

uninstall:
	$(KILL_SCRIPT)
	$(UNINSTALL_SCRIPT)

.PHONY: up down re clean check fclean logs status crash regen volume checks uninstall
