# =============================================================================
# VARIABLES & CONFIG
# =============================================================================

COMPOSE_FILE       = srcs/docker-compose.yml
COMPOSE            = docker compose -f $(COMPOSE_FILE)

CHECK_SCRIPT       = scripts/check_inception.sh
CRASH_SCRIPT       = scripts/crash_test.sh
VOLUME_SCRIPT      = scripts/volumes_check.sh
SECRET_GEN_SCRIPT  = scripts/generate_secrets.sh
ENV_GEN_SCRIPT     = scripts/generate_env.sh
KILL_SCRIPT        = scripts/kill_containers.sh
STATUS_SCRIPT      = scripts/status.sh
FTP_SCRIPT         = scripts/ftp.sh
EDIT_HOST_SCRIPT   = scripts/edit_hosts.sh

BOLD   = \033[1m
RESET  = \033[0m
RED    = \033[31m
GREEN  = \033[32m
YELLOW = \033[33m
BLUE   = \033[34m
CYAN   = \033[36m
WHITE  = \033[37m

# =============================================================================
# PROD
# =============================================================================

all: up check

help:
	@printf "\n${BOLD}Inception — Docker infrastructure${RESET}\n\n"
	@printf "${YELLOW}── production ──────────────────────────────────${RESET}\n"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make up"               "Build images and start all containers"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make down"             "Stop and remove containers"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make restart-<service>" "Restart a specific container"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make status"           "Show running containers and volumes"
	@printf "  ${RED}%-28s${RESET} ${RED}⚠  Full rebuild — DELETES persistent volumes${RESET}\n" "make re"
	@printf "\n${YELLOW}── development ──────────────────────────────────${RESET}\n"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make build-<service>"  "Rebuild a single service from scratch"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make logs"             "Follow all logs"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make logs-<service>"   "Follow logs of a specific service in a new terminal window"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make shell-<service>"  "Open a shell inside a specific container"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make check"            "Run inception validation checks"
	@printf "  ${CYAN}%-28s${RESET} %s\n" "make crash"            "Run crash tests"
	@printf "\n"

up: generate-env generate-secrets edit-host create-volumes
	@printf "${YELLOW}Starting containers ...${RESET}\n"
	$(COMPOSE) up -d --build --no-recreate

down:
	@printf "${YELLOW}Shutting down containers ...${RESET}\n"
	$(COMPOSE) down

restart-%:
	$(COMPOSE) restart $*

status:
	docker ps
	docker volume ls

re: kill delete-volumes create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

# =============================================================================
# DEV
# =============================================================================

build-%:
	@printf "${YELLOW}Rebuilding $* from scratch ...${RESET}\n"
	$(COMPOSE) up -d --build $*
logs:
	$(COMPOSE) logs -f

logs-%:
	alacritty -e sh -c '$(COMPOSE) logs -f $* | less +F' &

shell-%:
	alacritty -e sh -c '$(COMPOSE) exec $* sh'

check:
	$(CHECK_SCRIPT) $(SERVICE)

check-%:
	$(CHECK_SCRIPT) $*

crash:
	$(CRASH_SCRIPT)

# ============ File Transfer =============

ftp-list:
	$(FTP_SCRIPT) -l

ftp-dl-%:
	$(FTP_SCRIPT) -d $*

ftp-up-%:
	$(FTP_SCRIPT) -u $*

# ============= Cleanup =================

fclean: kill shutdown-remove-volumes clean-stop-containers delete-volumes clean-dangling-images remove-all-existing-images

uninstall: fclean clean-building-cache restore-host

reinstall: uninstall
	$(ENV_GEN_SCRIPT) -y
	$(SECRET_GEN_SCRIPT)
	$(EDIT_HOST_SCRIPT)
	$(MAKE) create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

# =============================================================================
# INTERNAL
# =============================================================================

shutdown-remove-volumes:
	@printf "${YELLOW}Shutting down and removing containers and volumes ...${RESET}\n"
	$(COMPOSE) down --volumes --remove-orphans

clean-stop-containers:
	@printf "${YELLOW}Cleaning stopped containers ...${RESET}\n"
	docker container prune -f

create-volumes:
	@printf "${YELLOW}Creating folders for persistent storage ...${RESET}\n"
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame
	sudo chown -R 82:82 ~/data/wordpress

delete-volumes:
	@printf "${YELLOW}Cleaning volumes ...${RESET}\n"
	@sudo rm -rf ~/data/mysql && printf "${GREEN}~/data/mysql deleted successfully${RESET}\n"
	@sudo rm -rf ~/data/chessgame && printf "${GREEN}~/data/chessgame deleted successfully${RESET}\n"
	@sudo rm -rf ~/data/wordpress && printf "${GREEN}~/data/wordpress deleted successfully${RESET}\n"
	@sudo rm -rf ~/data/hugo && printf "${GREEN}~/data/hugo deleted successfully${RESET}\n"

clean-dangling-images:
	@printf "${YELLOW}Cleaning dangling images ...${RESET}\n"
	docker image prune -f

remove-all-existing-images:
	@printf "${YELLOW}Removing images ...${RESET}\n"
	$(COMPOSE) down --rmi all

generate-env:
	$(ENV_GEN_SCRIPT)

regenerate-secrets:
	$(SECRET_GEN_SCRIPT) -f

edit-host:
	$(EDIT_HOST_SCRIPT)

generate-secrets:
	$(SECRET_GEN_SCRIPT)

restore-host:
	@printf "${YELLOW}Editing /etc/hosts...${RESET}\n"
	sudo sed -i '/^127\.0\.0\.1/d' /etc/hosts
	sudo sed -i 's/^#\(127\.0\.0\.1.*\)/\1/' /etc/hosts
	sudo cat /etc/hosts
	sudo sysctl vm.overcommit_memory=0

kill:
	@printf "${YELLOW}Killing containers ...${RESET}\n"
	$(KILL_SCRIPT)

clean-building-cache:
	@printf "${YELLOW}Cleaning builder cache...${RESET}\n"
	docker builder prune -f

remove-secrets-env:
	@printf "${YELLOW}Removing credentials and .env ...${RESET}\n"
	rm -rf secrets
	rm -rf srcs/.env

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regenerate-secrets create-volumes generate-env \
        generate-secrets kill shutdown-remove-volumes remove-all-existing-images \
        restore-host clean-stop-containers delete-volumes clean-building-cache \
        edit-host help
