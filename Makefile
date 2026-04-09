COMPOSE_FILE        = srcs/docker-compose.yml
COMPOSE             = docker compose -f $(COMPOSE_FILE)
CHECK_SCRIPT        = scripts/check_inception.sh
CRASH_SCRIPT        = scripts/crash_test.sh
VOLUME_SCRIPT       = scripts/volumes_check.sh
SECRET_GEN_SCRIPT   = scripts/generate_secrets.sh
ENV_GEN_SCRIPT      = scripts/generate_env.sh
KILL_SCRIPT         = scripts/kill_containers.sh
STATUS_SCRIPT       = scripts/status.sh
FTP_SCRIPT	 		= scripts/ftp.sh
EDIT_HOST_SCRIPT 	= scripts/edit_hosts.sh

YELLOW = \033[1;33m
NC = \033[0m

# =============================================================================
# PROD
# =============================================================================

all: up check

up: generate-env generate-secrets edit-host create-volumes
	@printf "${YELLOW}Starting containers ...${NC}\n"
	$(COMPOSE) up -d --build --no-recreate

down:
	@printf "${YELLOW}Shutting down containers ...${NC}\n"
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f $(SERVICE)

logs-%:
	alacritty -e sh -c '$(COMPOSE) logs -f $* | less +F' &

status:
	docker ps
	docker volume ls

restart-%:
	$(COMPOSE) restart $*

shell-%:
	alacritty -e sh -c '$(COMPOSE) exec $* sh'

ftp-list:
	$(FTP_SCRIPT) -l

ftp-dl-%:
	$(FTP_SCRIPT) -d $*

ftp-up-%:
	$(FTP_SCRIPT) -u $*

	# Ajouter un danger ici ? on veut delete les volumes ?
re: kill delete-volumes create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

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

fclean: kill shutdown-remove-volumes clean-stopped-containers delete-volumes clean-dangling-images remove-all-existing-images

uninstall: fclean clean-building-cache clean-building-cache restore-host

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
	@printf "${YELLOW}Shutting down and removing containers and volumes ...${NC}\n"
	$(COMPOSE) down --volumes --remove-orphans

clean-stop-containers:
	@printf "${YELLOW}Cleaning stopped containers ...${NC}\n"
	docker container prune -f

create-volumes:
	@printf "${YELLOW}Creating folders for persistent storage ...${NC}\n"
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame

delete-volumes:
	@printf "${YELLOW}Cleaning volumes ...${NC}\n"
	sudo rm -rf ~/data/mysql && echo "${YELLOW}~/data/mysql deleted successfully${NC}"
	sudo rm -rf ~/data/chessgame && echo "${YELLOW}~/data/chessgame deleted successfully${NC}"
	sudo rm -rf ~/data/wordpress && echo "${YELLOW}~/data/wordpress deleted successfully${NC}"
	sudo rm -rf ~/data/hugo && echo "${YELLOW}~/data/hugo deleted successfully${NC}"

clean-dangling-images:
	@printf "${YELLOW}Cleaning dangling images ...${NC}\n"
	docker image prune -f

remove-all-existing-images:
	@printf "${YELLOW}Removing images ...${NC}\n"
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
	@printf "${YELLOW}Editing /etc/hosts...${NC}\n"
	sudo sed -i '/^127\.0\.0\.1/d' /etc/hosts
	sudo sed -i 's/^#\(127\.0\.0\.1.*\)/\1/' /etc/hosts
	sudo cat /etc/hosts
	sudo sysctl vm.overcommit_memory=0

kill:
	@printf "${YELLOW}Killing containers ...${NC}\n"
	$(KILL_SCRIPT)

clean-building-cache:
	@printf "${YELLOW}Cleaning builder cache...${NC}\n"
	docker builder prune -f

remove-secrets-env:
	@printf "${YELLOW}Removing credentials and .env ...${NC}\n"
	rm -rf secrets
	rm -rf srcs/.env

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regenerate-secrets newmagicsite create-volumes generate-env \
        generate-secrets kill shutdown-remove-volumes remove-all-existing-images \
        restore-host clean-stopped-containers delete-volumes clean-building-cache edit-host
