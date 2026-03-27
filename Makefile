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
	mkdir -p ~/data/hugo
	mkdir -p ~/data/chessgame
	mkdir -p ~/data/llm-gen
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
	docker image prune -f
	sudo rm -rf ~/data/mysql
	sudo rm -rf ~/data/wordpress
	sudo rm -rf ~/data/hugo
	sudo rm -rf ~/data/chessgame
	sudo rm -rf ~/data/llm-gen
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

# Génère la page statique avec le LLM (container éphémère)
generate:
	@echo ">>> Generating static page via Groq LLM..."
	@if [ ! -f secrets/groq_api_key.txt ]; then \
		echo "ERROR: secrets/groq_api_key.txt not found."; \
		echo "Create it with: echo 'gsk_YOURKEY' > secrets/groq_api_key.txt"; \
		exit 1; \
	fi
	docker compose -f srcs/docker-compose.yml run --rm llm-gen
	@echo ">>> Static page generated."
 
# Régénère sans reconstruire l'image
regenerate:
	docker compose -f srcs/docker-compose.yml run --rm --no-deps llm-gen
 
# Build uniquement l'image llm-gen
build-llm:
	docker compose -f srcs/docker-compose.yml build llm-gen

.PHONY: up down re clean check fclean logs status crash regen volume checks uninstall build-llm regenerate generate
