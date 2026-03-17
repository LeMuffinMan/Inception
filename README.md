*This project has been created as part of the 42 curriculum by oelleaum.*

# Inception

## Description

Inception is a system administration / DevOps project that introduces Docker-based infrastructure management. The goal is to set up a small but complete web stack composed of multiple services, each running in its own dedicated container, orchestrated via Docker Compose inside a virtual machine.

The stack includes:
- **NGINX** — the sole entry point, serving HTTPS on port 443 using TLSv1.2 or TLSv1.3
- **WordPress + php-fpm** — the web application, running without NGINX
- **MariaDB** — the database backend, running without NGINX

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

### Configuration

1. Clone the repository inside your VM.

2. Create a `.env` from the `.env_example` provided and fill in your values:

```env
DOMAIN_NAME=<login>.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=<db_user>
```

3. The `secrets/` folder and all credential files are generated automatically when you run `make`. Missing files are created using `openssl rand` (or `/dev/urandom` as fallback if openssl is not available). You can also create the folder yourself and provide your own values — any file already present will not be overwritten.

The secrets used by the project are:

| File | Contents |
|---|---|
| `secrets/db_password.txt` | Password for the MariaDB application user |
| `secrets/db_root_password.txt` | Password for the MariaDB root user |
| `secrets/wp_admin_user.txt` | WordPress administrator username (must not contain "admin" or "administrator") |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user.txt` | WordPress regular user username |
| `secrets/wp_user_password.txt` | WordPress regular user password |
| `secrets/mysql_user.txt` | MariaDB application username |
| `secrets/mysql_admin_email.txt` | Email address for the WordPress administrator account |
| `secrets/mysql_user_email.txt` | Email address for the WordPress regular user account |

4. Add your domain to `/etc/hosts` on the VM:

```
127.0.0.1   <login>.42.fr
```

### Available commands

| Command | Description |
|---|---|
| `make` / `make all` | Generate missing secrets, create data directories, build images, start containers, then run the network check script |
| `make up` | Same as above without running `make check` at the end |
| `make down` | Stop and remove containers and networks, but preserve volumes and data |
| `make clean` | Stop and remove containers, networks, and volumes (data directories on the host are kept) |
| `make fclean` | Full cleanup: removes containers, volumes, images, build cache, and deletes `~/data` and the `secrets/` folder from the host. Requires `sudo` |
| `make re` | Runs `fclean` then `up` and `check` — full rebuild from scratch |
| `make check` | Runs the network check script to verify that containers are up and reachable |
| `make logs` | Streams live logs from all containers |
| `make status` | Shows the current status of all containers |
| `make crash` | Runs the crash test script (simulates a container failure), then re-runs the network check |
| `make volume` | Runs the volume check script, then re-runs the network check |
| `make checks` | Runs all check scripts: volume check, crash test, and network check |
| `make secrets` | Force-regenerates **all** secret files, overwriting any existing ones |

### Build and run

```bash
make
```

This will:
- Generate any missing secrets using `openssl rand` (or `/dev/urandom` as fallback)
- Create `~/data/mysql` and `~/data/wordpress` on the host
- Build all Docker images
- Start all containers in detached mode
- Run a basic network check script to overview the setup

The WordPress site will be reachable at `https://<login>.42.fr`.

### Stop the stack

```bash
make down
```

### Clean everything (including volumes and secrets)

```bash
make fclean
```

---

## Resources

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

### AI Usage
 
AI was used as a productivity tool for specific, well-defined tasks.
 
- **Documentation:** once the project was built and understood, AI was used to draft the structure and boilerplate content of this README, USER_DOC.md, and DEV_DOC.md, based on my own notes and the subject requirements. All content was reviewed and rewritten where needed.
- **Deepening concepts:** when encountering notions such as PID 1 behavior in containers, php-fpm socket configuration, or TLS certificate generation, AI was used as an interactive reference — to go further than documentation alone, ask follow-up questions, and clarify edge cases.
- **Placeholder generation:** AI was occasionally used to generate placeholder values, file templates, or boilerplate snippets to avoid repetitive writing, all of which were adapted and validated before use.
 
Every technical decision in this project was made, understood, and owned by me.
