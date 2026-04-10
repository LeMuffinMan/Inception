# =============================================================================
#  ██╗███╗   ██╗ ██████╗███████╗██████╗ ████████╗██╗ ██████╗ ███╗   ██╗
#  ██║████╗  ██║██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
#  ██║██╔██╗ ██║██║     █████╗  ██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║
#  ██║██║╚██╗██║██║     ██╔══╝  ██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║
#  ██║██║ ╚████║╚██████╗███████╗██║        ██║   ██║╚██████╔╝██║ ╚████║
#  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
# =============================================================================

# edit scripts/lib/config.sh to customize your inception setup

# =============================================================================
# VARIABLES & CONFIG
# =============================================================================

COMPOSE_FILE       = srcs/docker-compose.yml
COMPOSE            = docker compose -f $(COMPOSE_FILE)

CHECK_SCRIPT       = scripts/check_inception.sh
CRASH_SCRIPT       = scripts/crash_test.sh
SECRET_GEN_SCRIPT  = scripts/generate_secrets.sh
KILL_SCRIPT        = scripts/kill_containers.sh
FTP_SCRIPT         = scripts/ftp.sh
EDIT_HOST_SCRIPT   = scripts/edit_hosts.sh
SUDO_CHECK_SCRIPT  = scripts/check_sudo.sh

BOLD   = \033[1m
RESET  = \033[0m
RED    = \033[31m
GREEN  = \033[32m
YELLOW = \033[33m
BLUE   = \033[34m
CYAN   = \033[36m
WHITE  = \033[37m

# Log-level prefixes (for make output)
INFO_PFX = $(CYAN)[INFO] $(RESET)
WARN_PFX = $(YELLOW)$(BOLD)[WARN] $(RESET)
ERR_PFX  = $(RED)$(BOLD)[ERROR]$(RESET)
OK_PFX   = $(GREEN)[OK]   $(RESET)

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

up: check-sudo generate-secrets edit-host create-volumes
	@printf "$(INFO_PFX)Starting containers ...\n"
	$(COMPOSE) up -d --build --no-recreate

down:
	@printf "$(INFO_PFX)Shutting down containers ...\n"
	$(COMPOSE) down

restart-%:
	$(COMPOSE) restart $*

status:
	@docker ps
	@docker volume ls

re: check-sudo kill delete-volumes create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

# =============================================================================
# DEV
# =============================================================================

build-%:
	@printf "$(INFO_PFX)Rebuilding $* from scratch ...\n"
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

clean: down

fclean: check-sudo \
	kill \
	shutdown-remove-volumes \
	clean-stopped-containers \
	delete-volumes \
	clean-dangling-images \
	remove-all-existing-images

uninstall: fclean clean-building-cache restore-host

reinstall: uninstall
	$(SECRET_GEN_SCRIPT)
	$(EDIT_HOST_SCRIPT)
	$(MAKE) create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

# =============================================================================
# INTERNAL
# =============================================================================

shutdown-remove-volumes:
	@printf "$(WARN_PFX)Shutting down and removing containers and volumes ...\n"
	$(COMPOSE) down --volumes --remove-orphans

clean-stopped-containers:
	@printf "$(WARN_PFX)Cleaning stopped containers ...\n"
	docker container prune -f

create-volumes: check-sudo
	@printf "$(INFO_PFX)Creating folders for persistent storage ...\n"
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame

delete-volumes: check-sudo
	@printf "$(WARN_PFX)Cleaning volumes ...\n"
	@sudo rm -rf ~/data/mysql && printf "$(OK_PFX)~/data/mysql deleted\n"
	@sudo rm -rf ~/data/chessgame && printf "$(OK_PFX)~/data/chessgame deleted\n"
	@sudo rm -rf ~/data/wordpress && printf "$(OK_PFX)~/data/wordpress deleted\n"
	@sudo rm -rf ~/data/hugo && printf "$(OK_PFX)~/data/hugo deleted\n"

clean-dangling-images:
	@printf "$(WARN_PFX)Cleaning dangling images ...\n"
	docker image prune -f

remove-all-existing-images:
	@printf "$(WARN_PFX)Removing images ...\n"
	$(COMPOSE) down --rmi all

regenerate-secrets:
	$(SECRET_GEN_SCRIPT) -f

edit-host: check-sudo
	$(EDIT_HOST_SCRIPT)

generate-secrets:
	$(SECRET_GEN_SCRIPT)

restore-host: check-sudo
	@printf "$(INFO_PFX)Restoring /etc/hosts ...\n"
	sudo sed -i '/^127\.0\.0\.1/d' /etc/hosts
	sudo sed -i 's/^#\(127\.0\.0\.1.*\)/\1/' /etc/hosts
	sudo cat /etc/hosts
	sudo sysctl vm.overcommit_memory=0

kill:
	@printf "$(WARN_PFX)Killing containers ...\n"
	$(KILL_SCRIPT)

clean-building-cache:
	@printf "$(WARN_PFX)Cleaning builder cache ...\n"
	docker builder prune -f

remove-secrets-env:
	@printf "$(WARN_PFX)Removing credentials and .env ...\n"
	rm -rf secrets
	rm -rf srcs/.env

check-sudo:
	@printf "$(INFO_PFX)Checking sudo privileges ...\n"
	@$(SUDO_CHECK_SCRIPT)

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regenerate-secrets create-volumes \
        generate-secrets kill shutdown-remove-volumes remove-all-existing-images \
        restore-host clean-stopped-containers delete-volumes clean-building-cache \
        edit-host help ftp-list ftp-dl-% ftp-up-% check-sudo
