# USER_DOC — User Documentation

## What services does this stack provide?

The Inception stack runs three services:

| Service | Role |
|---|---|
| **NGINX** | Reverse proxy and HTTPS entry point (port 443) |
| **WordPress + php-fpm** | The website and its content management system |
| **MariaDB** | The database storing all WordPress data |

The only port exposed to the outside is **443** (HTTPS). All other communication happens internally between containers.

---

## Starting and stopping the project

### Start the stack

From the root of the repository on your virtual machine:

```bash
make
```

This builds the images (if not already built) and starts all containers in the background.

### Stop the stack (keep data)

```bash
make down
```

Containers are stopped and removed, but volumes (database, WordPress files) are preserved.

### Full cleanup (removes everything including data)

```bash
make fclean
```

> ⚠️ This will delete all stored data. Use with caution.

---

## Accessing the website and administration panel

Once the stack is running, open your browser and navigate to:

- **Website:** `https://<login>.42.fr`

> Your browser may show a certificate warning because the TLS certificate is self-signed. You can safely proceed by accepting the exception.

Replace `<login>` with the actual login configured in your `.env` file.

---

## Locating and managing credentials

All sensitive credentials are stored in the `secrets/` directory at the root of the repository. These files are **not tracked by git**.

| File | Contents |
|---|---|
| `secrets/db_password.txt` | Password for the MariaDB application user |
| `secrets/db_root_password.txt` | Password for the MariaDB root user |
| `secrets/credentials.txt` | WordPress administrator username and password |

To change credentials, edit the relevant file and rebuild the stack:

```bash
make fclean
make
```

Non-sensitive configuration (domain name, database name, usernames) is stored in `srcs/.env`.

---

## Checking that services are running correctly

### View running containers

```bash
docker ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `Up`.

### Check container logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Verify HTTPS is working

```bash
curl -k https://<login>.42.fr
```

You should receive the HTML content of the WordPress homepage.

### Check restart behavior

If a container crashes, it will restart automatically thanks to the `restart: on-failure` policy defined in `docker-compose.yml`.
