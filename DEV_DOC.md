# DEV_DOC — Developer Documentation

## Setting up the environment from scratch

### Prerequisites

The following must be installed on your virtual machine:

- **Docker** (recent stable version)
- **Docker Compose** (v2 recommended, used via `docker compose`)
- **make**
- **git**
- **openssl** (for generating the self-signed TLS certificate)

### Repository structure

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt        # WordPress admin user + password
│   ├── db_password.txt        # MariaDB app user password
│   └── db_root_password.txt   # MariaDB root password
└── srcs/
    ├── .env                   # Non-sensitive environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/          # nginx.conf / site config
        │   └── tools/         # entrypoint scripts
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/          # php-fpm pool config
        │   └── tools/         # wp-config / wp-cli setup scripts
        └── mariadb/
            ├── Dockerfile
            ├── conf/          # my.cnf or custom config
            └── tools/         # DB init scripts
```

### Configuration files to create

**`srcs/.env`** — environment variables (non-sensitive):

```env
DOMAIN_NAME=<login>.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

**`secrets/db_password.txt`** — one line, the MariaDB app user password.

**`secrets/db_root_password.txt`** — one line, the MariaDB root password.

**`secrets/credentials.txt`** — WordPress admin credentials, format:
```
WP_ADMIN_USER=<username>        # must NOT contain "admin" or "administrator"
WP_ADMIN_PASSWORD=<password>
WP_ADMIN_EMAIL=<email>
```

**`/etc/hosts`** on the VM — add this line:
```
127.0.0.1   <login>.42.fr
```

**Data directories** on the host — create them before the first run:
```bash
mkdir -p /home/<login>/data/db
mkdir -p /home/<login>/data/wordpress
```

---

## Building and launching with Make and Docker Compose

### Build all images and start the stack

```bash
make
```

This runs `docker compose -f srcs/docker-compose.yml up --build -d`.

### Stop containers without removing volumes

```bash
make down
```

### Rebuild a specific service

```bash
docker compose -f srcs/docker-compose.yml build <service>
docker compose -f srcs/docker-compose.yml up -d <service>
```

Replace `<service>` with `nginx`, `wordpress`, or `mariadb`.

---

## Useful commands for managing containers and volumes

### Container management

```bash
# List running containers
docker ps

# Access a container's shell
docker exec -it <container_name> sh

# View real-time logs
docker logs -f <container_name>

# Restart a single container
docker restart <container_name>
```

### Volume management

```bash
# List volumes
docker volume ls

# Inspect a volume (see mount path)
docker volume inspect <volume_name>
```

### Network

```bash
# Inspect the Docker network
docker network ls
docker network inspect <network_name>
```

### Full cleanup

```bash
# Stop and remove containers, networks, and volumes
make fclean

# Or manually:
docker compose -f srcs/docker-compose.yml down -v
docker system prune -af
```

---

## Data persistence

Both named volumes store data on the host machine under `/home/<login>/data`:

| Volume | Host path | Contents |
|---|---|---|
| `db_volume` | `/home/<login>/data/db` | MariaDB database files |
| `wp_volume` | `/home/<login>/data/wordpress` | WordPress core files and uploads |

These directories persist across container stops and restarts. Deleting them or running `make fclean` will permanently remove all stored data.

The volume configuration in `docker-compose.yml` looks like this:

```yaml
volumes:
  db_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/db
  wp_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/wordpress
```

> Note: while `driver_opts` with `type: none` resembles a bind mount, this is a named volume configuration as required by the subject. Pure bind mounts (using `volumes:` with a host path directly in the service definition) are not used.

---

## Key architectural rules (reminder for developers)

- No container uses `network: host`, `--link`, or `links:`.
- No container is started with infinite loop commands (`tail -f`, `sleep infinity`, `while true`, etc.).
- Containers run foreground processes as PID 1 — daemons are started directly, not via wrapper scripts that loop.
- No passwords are hardcoded in Dockerfiles — all sensitive values come from Docker secrets.
- The `latest` tag is forbidden for all images.
- NGINX is the **only** container exposed to the outside, on port **443** only, using **TLSv1.2 or TLSv1.3**.
