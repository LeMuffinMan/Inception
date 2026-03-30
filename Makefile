COMPOSE_FILE        = srcs/docker-compose.yml
COMPOSE             = docker compose -f $(COMPOSE_FILE)
CHECK_SCRIPT        = scripts/check_inception.sh
CRASH_SCRIPT        = scripts/crash_test.sh
VOLUME_SCRIPT       = scripts/volumes_check.sh
SECRET_GEN_SCRIPT   = scripts/generate_secrets.sh
ENV_GEN_SCRIPT      = scripts/generate_env.sh
FCLEAN_SCRIPT       = scripts/fclean.sh
UNINSTALL_SCRIPT    = scripts/uninstall.sh
KILL_SCRIPT         = scripts/kill_containers.sh
STATUS_SCRIPT       = scripts/status.sh

# =============================================================================
# PROD
# =============================================================================

all: up check

up: generate_env generate_secrets create_volumes
	@echo "Starting containers ..."
	$(COMPOSE) up -d --build --no-recreate

down:
	@echo "Shutting down containers ..."
	$(COMPOSE) down

re:
	$(COMPOSE) down
	$(MAKE) delete_volumes
	$(MAKE) create_volumes
	$(COMPOSE) up -d --build # --no-recreate
	$(MAKE) check

logs:
	$(COMPOSE) logs -f $(SERVICE)

logs-%:
	alacritty -e sh -c '$(COMPOSE) logs -f $* | less +F' &

status:
	docker ps
	docker volume ls
	docker network

restart:
	@[ -n "$(SERVICE)" ] || (echo "Usage: make restart SERVICE=<name>"; exit 1)
	$(COMPOSE) restart $(SERVICE)

shell:
	@[ -n "$(SERVICE)" ] || (echo "Usage: make shell SERVICE=<name>"; exit 1)
	alacritty -e sh -c '$(COMPOSE) exec $(SERVICE) sh'

# =============================================================================
# DEV
# =============================================================================

check:
ifeq ($(TEST),crash)
	$(CRASH_SCRIPT)
else ifeq ($(TEST),volume)
	$(VOLUME_SCRIPT)
else
	$(CHECK_SCRIPT) $(SERVICE)
endif

fclean:
	$(KILL_SCRIPT)
	$(FCLEAN_SCRIPT)

uninstall: fclean
	$(UNINSTALL_SCRIPT)

reinstall: uninstall
	$(ENV_GEN_SCRIPT) -y
	$(SECRET_GEN_SCRIPT)
	$(MAKE) create_volumes
	$(COMPOSE) up -d --build # --no-recreate
	$(MAKE) check

newmagicsite:
	@echo ">>> Generating static page via Groq LLM..."
	@if [ ! -f secrets/groq_api_key.txt ]; then \
		echo "ERROR: secrets/groq_api_key.txt not found."; \
		echo "Create it with: echo 'gsk_YOURKEY' > secrets/groq_api_key.txt"; \
		exit 1; \
	fi
	docker run --rm llm-gen
	@echo ">>> Static page generated."

# =============================================================================
# INTERNAL
# =============================================================================

create_volumes:
	@echo "Creating folders for persistent storage ..."
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame ~/data/llm-gen

delete_volumes:
	@echo "Deleting folders for persistent storage ..."
	sudo rm -rf ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame ~/data/llm-gen

generate_env:
	$(ENV_GEN_SCRIPT)

regenarate_secrets:
	$(SECRET_GEN_SCRIPT) -f

generate_secrets:
	$(SECRET_GEN_SCRIPT)

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regenerate_secrets newmagicsite create_volumes generate_env generate_secrets
