# DEV_DOC — Developer Documentation

## Setting up the environment from scratch

### Prerequisites

The following must be installed on your virtual machine:

- **Docker** 
- **Docker Compose** 
- **make**
- **git**
- **openssl** (used by the setup scripts to generate secrets, or it will use /dev/urandom as fallback)

> The project must be run inside a virtual machine. At least, with a sudo priviledged user: Some commands (notably `make fclean`) require `sudo` to remove volume data from the host filesystem.

---

### Repository structure

```
.
├── Makefile
├── srcs/
│    ├── .env                        # Generated automatically by make (gitignored)
│    ├── docker-compose.yml
│    └── requirements/
│        ├── nginx/
│        │   ├── Dockerfile
│        │   ├── conf/
│        │   └── tools/
│        ├── wordpress/
│        │   ├── Dockerfile
│        │   └── tools/
│        └── mariadb/
│            ├── Dockerfile
│            └── tools/
├── scripts/
│   ├── lib
│   │    ├── format.sh
│   │    └── config.sh
│   ├── check_inception.sh
│   ├── crash_test.sh
│   ├── volume_check.sh
│   └── generate_secrets.sh
│
└── secrets/                        # Generated automatically by make (gitignored)
   ├── db_password.txt
   ├── db_root_password.txt
   ├── mysql_user.txt
   ├── wp_admin_user.txt
   ├── wp_admin_password.txt
   ├── wp_user.txt
   ├── wp_user_password.txt
   ├── mysql_admin_email.txt
   └── mysql_user_email.txt
```

---

### Automated setup (recommended)

After cloning the repository inside your VM:

```bash
git clone https://github.com/LeMuffinMan/Inception
cd Inception && make
```

`make` handles the entire setup automatically:

1. Creates the `secrets/` folder and generates any missing secrets using `openssl rand` (or `/dev/urandom` as fallback). Any file already present in `secrets/` will **not** be overwritten, so you can provide your own values beforehand.
2. Creates `srcs/.env` with the required environment variables, derived from the current local username (`$(whoami)`).
3. Creates `~/data/mysql` and `~/data/wordpress` on the host.
4. Builds all Docker images.
5. Starts all containers in detached mode.
6. Runs a basic network check script to verify the setup.

The WordPress site will be reachable at `https://<login>.42.fr` or `https://localhost`.

---

### Manual setup (custom deployment)

If you prefer not to use the automated scripts, you must provide the following yourself.

#### 1. Secret files

Create the `secrets/` folder at the root of the repository and populate it with the following files (one value per file, no trailing newline):

**MariaDB**

| File | Contents |
|---|---|
| `secrets/db_password.txt` | MariaDB application user password |
| `secrets/db_root_password.txt` | MariaDB root user password |
| `secrets/mysql_user.txt` | MariaDB application username |

**WordPress**

| File | Contents |
|---|---|
| `secrets/wp_admin_user.txt` | Admin username — must **not** contain `admin` or `administrator` |
| `secrets/wp_admin_password.txt` | Admin password |
| `secrets/wp_user.txt` | Regular user username |
| `secrets/wp_user_password.txt` | Regular user password |
| `secrets/mysql_admin_email.txt` | Admin account email address |
| `secrets/mysql_user_email.txt` | Regular user email address |

#### 2. Environment file

Create `srcs/.env`:

```env
DOMAIN_NAME=<login>.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=<db_user>
WP_TITLE=<login>_wordpress
```

#### 3. Data directories

```bash
mkdir -p ~/data/mysql
mkdir -p ~/data/wordpress
```

#### 4. `/etc/hosts`

Edit the `127.0.0.1 localhost` line in `/etc/hosts` on the VM so the domain resolves to localhost:

```
127.0.0.1   <login>.42.fr
```

---

### Custom deployment for a new user

The scripts are designed to be fully portable across local users. To deploy as a new user:

```bash
sudo useradd -m -s /bin/bash <new_user>
sudo usermod -aG sudo <new_user>
sudo usermod -aG docker <new_user>
passwd <new_user>
su - <new_user>
```

Then clone and run:

```bash
git clone https://github.com/LeMuffinMan/Inception
cd Inception && make
```

All credentials and login-dependent variables are derived from the current username automatically.

To adjust defaults, edit `scripts/lib/config.sh`.

---

## Building and launching with Make and Docker Compose

### Build all images and start the stack

```bash
make
# or
make all
```

Generates missing secrets, creates data directories, builds all images, starts containers in detached mode, then runs the network check.

### Start without running checks

```bash
make up
```

Same as `make all` but skips the network check at the end.

### Stop containers (preserve volumes and data)

```bash
make down
```

Stops and removes containers and networks. Volume data on the host is preserved.

### Rebuild a specific service

```bash
docker compose -f srcs/docker-compose.yml build <service>
docker compose -f srcs/docker-compose.yml up -d <service>
```

Replace `<service>` with `nginx`, `wordpress`, or `mariadb`.

> Note: if volumes are not yet initialized, starting a dependent service in isolation (e.g. `wordpress` without `mariadb`) will cause it to fail. Always do a full `make` on first run.

---

## Useful commands for managing containers and volumes

### Container management

```bash
# List running containers
docker ps

# Access a container's shell
docker exec -it <container_name> sh

# View real-time logs for all containers
make logs

# Stream logs for a specific container
docker logs -f <container_name>

# Show current status of all containers
make status

# Restart a single container
docker restart <container_name>
```

### Volume management

```bash
# List volumes
docker volume ls

# Inspect a volume (see mount path and configuration)
docker volume inspect <volume_name>
```

### Network

```bash
# List Docker networks
docker network ls

# Inspect the project network
docker network inspect <network_name>
```

### Check and test scripts

```bash
# Run the network check (verify containers are up and reachable)
make check

# Run volume persistence test, then network check
make volume

# Run crash test (simulates container failure), then network check
make crash

# Run all checks: volume, crash, and network
make checks
```

---

## Cleanup commands

| Command | Effect |
|---|---|
| `make down` | Stop and remove containers and networks; preserve volumes and data |
| `make clean` | Stop and remove containers, networks, and volumes; keep host data directories |
| `make fclean` | Full cleanup: removes containers, volumes, images, build cache, and deletes `~/data` and `secrets/` from the host. **Requires `sudo`** |
| `make re` | Runs `fclean` then `up` and `checks` — full rebuild from scratch |
| `make secrets` | Force-regenerates **all** secret files, overwriting existing ones |

---

## Data persistence

Both named volumes store data on the host machine under `~/data`:

| Volume | Host path | Contents |
|---|---|---|
| `db_volume` | `~/data/mysql` | MariaDB database files |
| `wp_volume` | `~/data/wordpress` | WordPress core files and uploads |

These directories survive container stops, restarts, and rebuilds. They are only removed by `make fclean` (which deletes them from the host entirely) or `make clean` (which removes the Docker volumes but leaves the host directories intact).

The named volume configuration in `docker-compose.yml` uses `driver_opts` to bind to the host paths while remaining proper named volumes (not raw bind mounts, which are forbidden by the subject):

```yaml
volumes:
  db_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/mysql
  wp_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/wordpress
```

---

## Key architectural constraints (reminder)

- No container uses `network: host`, `--link`, or `links:`.
- No container is started with infinite-loop commands (`tail -f`, `sleep infinity`, `while true`, `bash`, etc.).
- Containers run foreground processes as PID 1 — daemons are invoked directly, not wrapped in looping scripts.
- No passwords are hardcoded in Dockerfiles — all sensitive values are injected via Docker secrets.
- The `latest` tag is forbidden for all images.
- Images are built from the penultimate stable version of Alpine or Debian.
- NGINX is the **only** container exposed to the outside, on port **443** only, using **TLSv1.2 or TLSv1.3**.
- The WordPress database contains two users: one administrator (username must not contain `admin` or `administrator`) and one regular user.
