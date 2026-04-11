*This project has been created as part of the 42 curriculum by oelleaum.*

# Inception

## Description

Inception is a system administration / DevOps project that introduces Docker-based infrastructure management. The goal is to set up a small but complete web stack composed of multiple services, each running in its own dedicated container, orchestrated via Docker Compose inside a virtual machine.

The stack includes:
- **NGINX** — the sole entry point, serving HTTPS on port 443 using TLSv1.2 or TLSv1.3
- **WordPress + php-fpm** — the web application, running without NGINX
- **MariaDB** — the database backend, running without NGINX
- **Redis** — object cache for WordPress (bonus)
- **Adminer** — web-based database management UI (bonus)
- **vsftpd** — FTP server with access to the WordPress volume (bonus)
- **Hugo** — static site served alongside WordPress (bonus)
- **ChessGame** — additional static app served by NGINX (bonus)

All Docker images are built from scratch using custom Dockerfiles based on the penultimate stable version of Alpine or Debian. No pre-built images from Docker Hub are used (except the base Alpine OS image).

### Design

#### Virtual Machines vs Docker
A virtual machine emulates an entire operating system with its own kernel, offering strong isolation but consuming significant resources (RAM, disk, CPU). Docker containers share the host kernel and are far more lightweight — they start faster and use less memory. However, containers offer a weaker isolation boundary than VMs. In this project, Docker runs *inside* a VM to get the benefits of both approaches.

#### Secrets vs Environment Variables
Environment variables (stored in a `.env` file) are suitable for non-sensitive configuration such as domain names, usernames, or port numbers. Docker secrets, on the other hand, are designed for sensitive data like passwords and API keys — they are stored securely and mounted into containers as files, never exposed in environment listings or image layers. In this project, passwords are managed via Docker secrets, while general configuration uses `.env`.

#### Docker Network vs Host Network
With `network: host`, the container shares the host's network stack directly — no isolation, no port mapping. A Docker network (bridge mode) creates an isolated virtual network where containers can communicate with each other by service name, while remaining invisible to the outside world unless a port is explicitly exposed. This project uses a custom Docker network to keep inter-service communication internal and controlled.

#### Docker Volumes vs Bind Mounts
Bind mounts link a specific path on the host filesystem directly to the container — convenient for development but fragile and host-dependent. Named Docker volumes are managed by Docker itself, are portable, and survive container restarts and rebuilds. This project uses named volumes for the WordPress database and website files, stored under `~/data` on the host.

---

## Instructions

### Prerequisites

- A **virtual machine** running Linux. Running the project inside a VM is required — both to understand the virtualization concepts at the heart of this project, and because some commands (such as `make fclean`) require `sudo` privileges to remove volume data from the host filesystem.
- Docker and Docker Compose installed on the VM
- `make` installed on the VM

### Configuration and build

#### Fast configuration
After cloning the repository inside your VM:
```
git clone https://github.com/LeMuffinMan/Inception
```
Using the scripts provided, you are ready to build and run, by simply using `make`.
```
cd Inception && make
```
The `make` command will:
- Prompt to generate `srcs/.env` with default values derived from the current user
- Fill in any missing `.env` variables interactively
- Create the `secrets/` folder and generate any missing secret files using `openssl rand` (or `/dev/urandom` as fallback). Any file already present will not be overwritten.
- Prompt to edit `/etc/hosts` to redirect `localhost` to your domain
- Enable `vm.overcommit_memory` for Redis (required for correct cache behavior)
- Create `~/data/mysql`, `~/data/wordpress`, `~/data/hugo`, and `~/data/chessgame` on the host
- Build all Docker images
- Start all containers in detached mode
- Run a basic network check script to overview the setup

The WordPress site will be reachable at `https://<login>.42.fr`.

#### Custom deployment
For a custom setup, edit `scripts/lib/config.sh`. By default, the scripts use `$(whoami)` to derive the login value, which allows easy multi-user deployment:

```bash
sudo useradd -m -s /bin/bash <new_user>
sudo usermod -aG sudo <new_user>
sudo usermod -aG docker <new_user>
passwd <new_user>
su - <new_user>
git clone https://github.com/LeMuffinMan/Inception
cd Inception && make
```

All credentials and login-dependent variables will be set based on the new local username.

#### Manual setup
Without using the setup scripts, you must provide:

**Secret files** in `secrets/` (one value per file):

| File | Contents |
|---|---|
| `secrets/db_password.txt` | MariaDB application user password |
| `secrets/db_root_password.txt` | MariaDB root user password |
| `secrets/wp_admin_password.txt` | WordPress admin password |
| `secrets/wp_user_password.txt` | WordPress regular user password |
| `secrets/ftp_pass.txt` | FTP user password |

**Environment file** `srcs/.env`:
```env
DOMAIN_NAME=<login>.42.fr
MYSQL_DATABASE=<login>_db
MYSQL_USER=<login>_mysql_user
MYSQL_USER_EMAIL=<login>@mail.fr
MYSQL_ADMIN_EMAIL=<login>_su@mail.fr
WP_TITLE=<login>_wordpress
WP_USER=<login>_wordpress_user
WP_ADMIN_USER=<login>_wordpress_su
FTP_USER=<login>
```

**`/etc/hosts`** — add the following line:
```
127.0.0.1   <login>.42.fr
```

### Available commands

| Command | Description |
|---|---|
| `make` / `make all` | Generate missing secrets and `.env`, edit hosts, create data directories, build images, start containers, run the check script |
| `make up` | Same as above without running the check script |
| `make down` | Stop and remove containers and networks; preserve volumes and data |
| `make re` | Kill containers, wipe volumes, rebuild and restart everything from scratch |
| `make restart-<service>` | Restart a specific container (e.g. `make restart-nginx`) |
| `make status` | Show running containers and volumes |
| `make build-<service>` | Rebuild a single service image from scratch |
| `make logs` | Stream live logs from all containers |
| `make logs-<service>` | Stream logs of a specific service in a new terminal window |
| `make shell-<service>` | Open a shell inside a specific container |
| `make check` | Run the inception validation script (all services) |
| `make check-<service>` | Run the validation script for a specific service only |
| `make crash` | Kill each container's PID and verify automatic restart |
| `make ftp-list` | List files on the FTP server |
| `make ftp-dl-<file>` | Download a file from the FTP server |
| `make ftp-up-<file>` | Upload a file to the FTP server |
| `make regenerate-secrets` | Force-regenerate all secret files (overwrites existing) |
| `make clean` | Stop and remove containers (alias for `make down`) |
| `make fclean` | Full cleanup: removes containers, volumes, images, and build cache. **Requires `sudo`** |
| `make uninstall` | Runs `fclean`, restores `/etc/hosts`, then prompts to delete `secrets/` and `srcs/.env` |
| `make reinstall` | Runs `uninstall` then regenerates secrets, edits hosts, and rebuilds everything |

---

## Sources

### Docker & Infrastructure

- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB Docker setup guide](https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/)
- [WordPress CLI documentation](https://wp-cli.org/)
- [php-fpm configuration guide](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Understanding PID 1 in Docker containers](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)
- [TLS 1.2 vs TLS 1.3 overview](https://www.cloudflare.com/learning/ssl/why-use-tls-1.3/)
- [Redis memory overcommit](https://aws.plainenglish.io/resolving-redis-memory-overcommit-must-be-enabled-error-4b4d32ac050c)
- [vsftpd configuration reference](https://www.linuxtricks.fr/wiki/vsftpd-le-fichier-de-configuration-vsftpd-conf)

### AI Usage

AI was used as a productivity tool for specific, well-defined tasks.

- **Documentation:** once the project was built and understood, AI was used to draft the structure and boilerplate content of this README, USER_DOC.md, and DEV_DOC.md, based on my own notes and the subject requirements. All content was reviewed and rewritten where needed.
- **Deepening concepts:** when encountering notions such as PID 1 behavior in containers, php-fpm socket configuration, or TLS certificate generation, AI was used as an interactive reference — to go further than documentation alone, ask follow-up questions, and clarify edge cases.
- **Placeholder generation:** AI was occasionally used to generate placeholder values, file templates, or boilerplate snippets to avoid repetitive writing, all of which were adapted and validated before use.

Every technical decision in this project was made, understood, and owned by me.
