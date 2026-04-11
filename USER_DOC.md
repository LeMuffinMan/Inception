# USER_DOC — User Documentation

## What services does this stack provide?

The Inception stack runs several services, all communicating over an isolated Docker network:

| Service | Role |
|---|---|
| **NGINX** | Reverse proxy and HTTPS entry point (port 443, TLSv1.2/1.3) |
| **WordPress + php-fpm** | The website and its content management system |
| **MariaDB** | The database storing all WordPress data |
| **Redis** | Object cache for WordPress — speeds up repeated page loads |
| **Adminer** | Web-based database management UI, accessible at `/adminer` |
| **vsftpd** | FTP server with access to the WordPress volume |
| **Hugo** | Static site generator served at `/muffin_site` |
| **ChessGame** | Static app served at `/chessgame` |

The only port exposed to the outside world is **443** (HTTPS). All other communication happens internally between containers and is not reachable from outside the VM.

**NGINX** acts as the front door of the stack. It is the only service that directly receives requests from your browser, over an encrypted HTTPS connection. It then forwards those requests to WordPress and sends back the response. No other service is directly accessible from outside.

**WordPress + php-fpm** is the application itself — it generates the web pages, handles user logins, manages content, and serves the administration panel. It never communicates directly with the outside world; it only receives requests forwarded by NGINX, and reads or writes data through MariaDB.

**MariaDB** is the database. It stores everything WordPress needs to function: pages, posts, users, settings, and more. It has no contact with the outside world whatsoever — it only responds to requests from WordPress.

**Redis** acts as an in-memory object cache between WordPress and MariaDB. Frequently accessed data is stored in Redis so WordPress does not need to query the database on every request.

**Adminer** is a lightweight database management interface. It is accessible through NGINX at `https://<login>.42.fr/adminer` — its port is not exposed directly to the host.

**vsftpd** provides FTP access to the WordPress volume, allowing you to upload or download files without entering the container directly.

---

## Prerequisites

This project runs inside a **Linux virtual machine** with Docker, Docker Compose, and `make` installed. Make sure you are running all commands from within the VM.
Some commands require `sudo` privileges.

---

## Starting and stopping the project

### Start the stack

From the root of the repository on your virtual machine:

```bash
make
```

This will:
- Prompt to generate `srcs/.env` with default values, then fill any missing variables interactively
- Generate any missing secret files (passwords)
- Prompt to edit `/etc/hosts` and enable memory overcommit for Redis
- Create data directories on the host
- Build all Docker images and start all containers in the background
- Run a validation script to confirm everything is up

### Start without running checks

```bash
make up
```

Same as `make`, but skips the final validation script.

### Stop the stack (keep data)

```bash
make down
```

Containers are stopped and removed, but volumes (database, WordPress files) are preserved. Running `make` again will bring everything back up with your data intact.

### Restart a single container

```bash
make restart-<service>
```

For example: `make restart-nginx`, `make restart-wordpress`.

### Full cleanup (removes everything)

```bash
make fclean
```

Removes all containers, Docker volumes, images, and build cache. Data directories on the host (`~/data`) are also deleted. **Requires `sudo`.**

### Uninstall completely

```bash
make uninstall
```

Runs `fclean`, restores `/etc/hosts` to its original state, then prompts you individually to confirm deletion of `secrets/` and `srcs/.env`.

### Reinstall from scratch

```bash
make reinstall
```

Runs `uninstall`, then regenerates secrets, edits hosts, and rebuilds the entire stack.

---

## Accessing the website and administration panel

Once the stack is running, open your browser and navigate to:

| URL | Content |
|---|---|
| `https://<login>.42.fr` | WordPress homepage |
| `https://<login>.42.fr/wp-admin` | WordPress administration panel |
| `https://<login>.42.fr/adminer` | Adminer database management UI |
| `https://<login>.42.fr/muffin_site` | Hugo static site |
| `https://<login>.42.fr/chessgame` | ChessGame static app |

> Your browser may show a certificate warning because the TLS certificate is self-signed. You can safely proceed by accepting the exception.

To log into the WordPress administration panel, use the credentials stored in `secrets/wp_admin_password.txt` and the admin username from `srcs/.env` (`WP_ADMIN_USER`).

---

## Locating and managing credentials

All sensitive passwords are stored as plain text files in the `secrets/` directory at the root of the repository. These files are **not tracked by git** and must never be committed.

**Auto-generated password files:**

| File | Contents |
|---|---|
| `secrets/db_password.txt` | Password for the MariaDB application user |
| `secrets/db_root_password.txt` | Password for the MariaDB root user |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user_password.txt` | WordPress regular user password |
| `secrets/ftp_pass.txt` | FTP user password |

These files are generated automatically on first `make`. Any file already present will **not** be overwritten, so you can provide your own values before running `make` for the first time.

**Usernames and non-sensitive configuration** are stored in `srcs/.env` and are also generated on first `make` with defaults derived from your local username.

To force-regenerate all secret files (passwords only — overwrites existing values):

```bash
make regenerate-secrets
```

### Where is the data stored?

WordPress files and the MariaDB database are persisted in named Docker volumes. On the host machine, this data is located at:

- `~/data/wordpress` — WordPress website files
- `~/data/mysql` — MariaDB database files
- `~/data/hugo` — Hugo static site files
- `~/data/chessgame` — ChessGame static app files

These directories survive container restarts and rebuilds. They are only removed by `make fclean`.

---

## Checking that services are running correctly

### Quick status overview

```bash
make status
```

All containers should appear with status `Up`.

### Run the built-in validation script

```bash
make check
```

Runs the full validation script: checks that every container is up, healthy, reachable on the expected port, and passes service-specific probes (TLS version, MariaDB query, Redis PING, FTP listing, WordPress user count, project integrity).

```bash
make check-<service>
```

Runs the same script but for a single service only. For example: `make check-nginx`, `make check-mariadb`, `make check-redis`.

### Stream live logs

```bash
make logs
```

Streams live logs from all containers. To follow logs for a single service in a dedicated terminal window:

```bash
make logs-<service>
```

### Open a shell inside a container

```bash
make shell-<service>
```

Opens an interactive shell inside the specified container in a new terminal window.

### Simulate a crash and verify recovery

```bash
make crash
```

Kills each container's main process with `kill -9` and verifies that Docker's restart policy brings it back up and healthy. Also tests a simultaneous crash of all containers.

---

## FTP access

The vsftpd container exposes an FTP server on port 21. You can interact with it using the provided make targets:

```bash
make ftp-list              # List files in the WordPress volume
make ftp-dl-<file>         # Download a file (e.g. make ftp-dl-wp-config.php)
make ftp-up-<file>         # Upload a file (e.g. make ftp-up-myfile.txt)
```

Credentials are read automatically from `secrets/ftp_pass.txt` and the `FTP_USER` variable in `srcs/.env`.

---

## All available commands

| Command | Description |
|---|---|
| `make` / `make all` | Generate secrets and `.env`, edit hosts, create data dirs, build images, start containers, run check |
| `make up` | Same as above without running the check script |
| `make down` | Stop and remove containers; preserve volumes and data |
| `make re` | Kill containers, wipe volumes, rebuild everything from scratch |
| `make restart-<service>` | Restart a specific container |
| `make status` | Show running containers and volumes |
| `make build-<service>` | Rebuild a single service image from scratch |
| `make logs` | Stream live logs from all containers |
| `make logs-<service>` | Stream logs of a specific service in a new terminal window |
| `make shell-<service>` | Open a shell inside a specific container |
| `make check` | Run the full validation script |
| `make check-<service>` | Run validation for a specific service only |
| `make crash` | Kill container PIDs and verify automatic restart |
| `make ftp-list` | List files on the FTP server |
| `make ftp-dl-<file>` | Download a file from the FTP server |
| `make ftp-up-<file>` | Upload a file to the FTP server |
| `make regenerate-secrets` | Force-regenerate all password files (overwrites existing) |
| `make clean` | Stop and remove containers (alias for `make down`) |
| `make fclean` | Full cleanup: removes containers, volumes, images, and build cache. **Requires `sudo`** |
| `make uninstall` | `fclean` + restore `/etc/hosts` + prompt to delete `secrets/` and `srcs/.env` |
| `make reinstall` | `uninstall` then regenerate secrets, edit hosts, and rebuild everything |
