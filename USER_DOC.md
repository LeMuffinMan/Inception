# USER_DOC — User Documentation

## What services does this stack provide?

The Inception stack runs three services, all communicating over an isolated Docker network:

| Service | Role |
|---|---|
| **NGINX** | Reverse proxy and HTTPS entry point (port 443, TLSv1.2/1.3) |
| **WordPress + php-fpm** | The website and its content management system |
| **MariaDB** | The database storing all WordPress data |

The only port exposed to the outside world is **443** (HTTPS). All other communication happens internally between containers and is not reachable from outside the VM.

---

## Prerequisites

This project runs inside a **Linux virtual machine** with Docker, Docker Compose, and `make` installed. Make sure you are running all commands from within the VM.

---

## Starting and stopping the project

### Start the stack

From the root of the repository on your virtual machine:

```bash
make
```

This will generate any missing secrets, create data directories, build all Docker images, and start all containers in the background. A network check is also run at the end to confirm everything is up.

### Start without running checks

```bash
make up
```

Same as `make`, but skips the final check script.

### Stop the stack (keep data)

```bash
make down
```

Containers are stopped and removed, but volumes (database, WordPress files) are preserved. Running `make` again will bring everything back up with your data intact.

### Full cleanup (removes everything including data)

```bash
make fclean
```

> ⚠️ This will permanently delete all stored data, secrets, and built images. Use with caution.

---

## Accessing the website and administration panel

Once the stack is running, open your browser and navigate to:

- **Website:** `https://<login>.42.fr`
- **Administration panel:** `https://<login>.42.fr/wp-admin`

Replace `<login>` with the login configured in your `.env` file (e.g. `https://oelleaum.42.fr`).

> Your browser may show a certificate warning because the TLS certificate is self-signed. You can safely proceed by accepting the exception.

To log into the administration panel, use the WordPress admin credentials stored in `secrets/wp_admin_user.txt` and `secrets/wp_admin_password.txt`.

---

## Locating and managing credentials

All sensitive credentials are stored as plain text files in the `secrets/` directory at the root of the repository. These files are **not tracked by git** and must never be committed.

**MariaDB secrets:**

| File | Contents |
|---|---|
| `secrets/db_password.txt` | Password for the MariaDB application user |
| `secrets/db_root_password.txt` | Password for the MariaDB root user |
| `secrets/mysql_user.txt` | MariaDB application username |

**WordPress secrets:**

| File | Contents |
|---|---|
| `secrets/wp_admin_user.txt` | WordPress administrator username |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user.txt` | WordPress regular user username |
| `secrets/wp_user_password.txt` | WordPress regular user password |
| `secrets/mysql_admin_email.txt` | Administrator account email |
| `secrets/mysql_user_email.txt` | Regular user email |

The `secrets/` folder and all its contents are auto-generated on first `make`. Any file already present will **not** be overwritten, so you can provide your own values before running `make` for the first time.

To force-regenerate all secrets (this will overwrite existing values):

```bash
make secrets
```

Non-sensitive configuration (domain name, database name, usernames) is stored in `srcs/.env`.

### Where is the data stored?

WordPress files and the MariaDB database are persisted in named Docker volumes. On the host machine, this data is located at:

- `~/data/wordpress` — WordPress website files
- `~/data/mysql` — MariaDB database files

These directories survive container restarts and rebuilds. They are only removed by `make fclean`.

---

## Checking that services are running correctly

### Quick status overview

```bash
make status
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `Up`.

### Run the built-in network check

```bash
make check
```

This script verifies that all containers are up and reachable on the expected ports.

### Stream live logs

```bash
make logs
```

Useful for diagnosing issues in real time across all services.

### Verify HTTPS is working

```bash
curl -k https://<login>.42.fr
```

You should receive the HTML content of the WordPress homepage.

### Automatic restart on crash

If a container crashes, it will restart automatically thanks to the restart policy defined in `docker-compose.yml`. You can simulate a crash and verify recovery with:

```bash
make crash
```
