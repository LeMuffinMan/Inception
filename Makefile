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

YELLOW = \033[1;33m
NC = \033[0m

# =============================================================================
# PROD
# =============================================================================

all: up check

up: generate-env generate-secrets create-volumes
	@echo "${YELLOW}Starting containers ...${NC}"
	$(COMPOSE) up -d --build --no-recreate

down:
	@echo "${YELLOW}Shutting down containers ...${NC}"
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

uninstall: fclean clean-building-cache clean-building-cache

reinstall: uninstall
	$(ENV_GEN_SCRIPT) -y
	$(SECRET_GEN_SCRIPT)
	$(MAKE) create-volumes
	$(COMPOSE) up -d --build
	$(MAKE) check

# =============================================================================
# INTERNAL
# =============================================================================

shutdown-remove-volumes:
	@echo "${YELLOW}Shutting down and removing containers and volumes ...${NC}"
	$(COMPOSE) down --volumes --remove-orphans

clean-stop-containers:
	echo "${YELLOW}Cleaning stopped containers ...${NC}"
	docker container prune -f

create-volumes:
	@echo "${YELLOW}Creating folders for persistent storage ...${NC}"
	mkdir -p ~/data/mysql ~/data/wordpress ~/data/hugo ~/data/chessgame ~/data/llm-gen

delete-volumes:
	echo "${YELLOW}Cleaning volumes ...${NC}"
	sudo rm -rf ~/data/mysql && echo "${YELLOW}~/data/mysql deleted successfully${NC}"
	sudo rm -rf ~/data/chessgame && echo "${YELLOW}~/data/chessgame deleted successfully${NC}"
	sudo rm -rf ~/data/wordpress && echo "${YELLOW}~/data/wordpress deleted successfully${NC}"
	sudo rm -rf ~/data/hugo && echo "${YELLOW}~/data/hugo deleted successfully${NC}"
	#A VIRER !!!
	sudo rm -rf ~/data/llm-gen && echo "${YELLOW}~/data/llm-gen deleted successfully${NC}"

clean-dangling-images:
	echo "${YELLOW}Cleaning dangling images ...${NC}"
	docker image prune -f

remove-all-existing-images:
	echo "${YELLOW}Removing images ...${NC}"
	$(COMPOSE) down --rmi all

generate-env:
	$(ENV_GEN_SCRIPT)

regenerate-secrets:
	$(SECRET_GEN_SCRIPT) -f

generate-secrets:
	$(SECRET_GEN_SCRIPT)

restore-hosts:
	@echo "${YELLOW}Editing /etc/hosts ...${NC}"
	sudo sed -i 's/^127\.0\.0\.1\s\+.*/127.0.0.1\tlocalhost/' /etc/hosts
	sudo sed -i '/^#\?127\.0\.0\.1/{ /^127\.0\.0\.1\tlocalhost$/!d }' /etc/hosts
	sudo cat /etc/hosts

kill:
	@echo "${YELLOW}Killing containers ...${NC}"
	$(KILL_SCRIPT)

clean-building-cache:
	@echo "${YELLOW}Cleaning builder cache...${NC}"
	docker builder prune -f

remove-secrets-env:
	echo -e "${YELLOW}Removing credentials and .env ...${NC}"
	rm -rf secrets
	rm -rf srcs/.env

.PHONY: all up down re logs status restart shell check fclean uninstall \
        reinstall regenerate-secrets newmagicsite create-volumes generate-env \
        generate-secrets kill shutdown-remove-volumes remove-all-existing-images \
        restore-hosts clean-stopped-containers delete-volumes clean-building-cache
