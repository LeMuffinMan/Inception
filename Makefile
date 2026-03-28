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
	@bash $(KILL_SCRIPT)
	sudo rm -rf ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame ~/data/llm-gen
	$(MAKE) up
	$(MAKE) check

logs:
	$(COMPOSE) logs -f $(SERVICE)

logs-%:
	alacritty -e sh -c '$(COMPOSE) logs -f $* | less +F' &

status:
	@bash $(STATUS_SCRIPT)

restart:
	@[ -n "$(SERVICE)" ] || (echo "Usage: make restart SERVICE=<name>"; exit 1)
	$(COMPOSE) restart $(SERVICE)

shell:
	@[ -n "$(SERVICE)" ] || (echo "Usage: make shell SERVICE=<name>"; exit 1)
	$(COMPOSE) exec $(SERVICE) sh

# =============================================================================
# DEV
# =============================================================================

check:
ifeq ($(TEST),crash)
	@bash $(CRASH_SCRIPT)
else ifeq ($(TEST),volume)
	@bash $(VOLUME_SCRIPT)
else
	@bash $(CHECK_SCRIPT) $(SERVICE)
endif

fclean:
	@bash $(FCLEAN_SCRIPT)

uninstall: fclean
	@bash $(UNINSTALL_SCRIPT)

reinstall: uninstall up

regen:
	$(SECRET_GEN_SCRIPT) -f

hosts:
	@grep -q "$(shell whoami).42.fr" /etc/hosts \
		&& echo "/etc/hosts entry already present" \
		|| (sudo sed -i 's/^127\.0\.0\.1.*/& $(shell whoami).42.fr/' /etc/hosts \
			&& echo "Added $(shell whoami).42.fr to /etc/hosts")

newmagicsite:
	@echo ">>> Generating static page via Groq LLM..."
	@if [ ! -f secrets/groq_api_key.txt ]; then \
		echo "ERROR: secrets/groq_api_key.txt not found."; \
		echo "Create it with: echo 'gsk_YOURKEY' > secrets/groq_api_key.txt"; \
		exit 1; \
	fi
	$(COMPOSE) run --rm llm-gen
	@echo ">>> Static page generated."

# =============================================================================
# INTERNAL
# =============================================================================

create_volumes:
	@echo "Creating folders for persistent storage ..."
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame ~/data/llm-gen

generate_env:
	$(ENV_GEN_SCRIPT)

generate_secrets:
	$(SECRET_GEN_SCRIPT)

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regen hosts newmagicsite create_volumes generate_env generate_secrets
