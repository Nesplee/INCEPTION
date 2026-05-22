*This project has been created as part of the 42 curriculum by dinguyen.*

# Inception

## Description

Inception is a system administration project that consists of setting up a small infrastructure composed of different services using Docker and Docker Compose, running inside a personal virtual machine.

Each service runs in its own dedicated container, built from a custom `Dockerfile`. No pre-built images are used (Alpine and Debian base images are the only exceptions). The entire infrastructure is orchestrated through a single `docker-compose.yml` file and launched via a `Makefile`.

The mandatory stack includes NGINX (as the sole HTTPS entry point), WordPress with PHP-FPM, and MariaDB. Five bonus services extend the infrastructure: a Redis cache, an FTP server, a static website, Adminer, and n8n as the free-choice service.

---

## Project Description

### Virtual Machines vs Docker

A virtual machine emulates an entire computer, including its own kernel, via a hypervisor (e.g. VirtualBox, VMware). It is heavy (several GB) and slow to start.

Docker containers share the host machine's Linux kernel and isolate processes using Linux namespaces (PID, network, filesystem) and cgroups (CPU/RAM limits). They are lightweight (a few MB) and start in seconds.

In this project, the entire infrastructure runs inside a single VM, and each service runs in its own Docker container — combining both levels of isolation.

### Secrets vs Environment Variables

Environment variables (stored in a `.env` file) are injected at runtime into the container's environment. They are convenient but exist in plaintext in the process environment and can be inspected with `docker inspect`.

Docker secrets are files mounted into containers at `/run/secrets/` with strict access permissions. They are the recommended approach for sensitive data in production.

In this project, credentials are stored in a `.env` file (never committed to git) and injected via `env_file` in `docker-compose.yml`. The `.env` file is listed in `.gitignore` and only `.env.example` (with placeholder values) is versioned.

### Docker Network vs Host Network

`network: host` removes all network isolation — the container shares the host's network stack directly. It is forbidden in this project.

A Docker bridge network (`driver: bridge`) creates an isolated virtual subnet. Containers on the same bridge network communicate using their service name as a hostname (internal DNS). Only NGINX exposes a port to the outside (`443:443`). All other services (MariaDB, WordPress, Redis) are only reachable from within the `inception` network.

### Docker Volumes vs Bind Mounts

A **bind mount** maps a specific host path directly into a container (`-v /host/path:/container/path`). It gives full control over the location but is not managed by Docker and does not appear in `docker volume ls`.

A **Docker named volume** is managed by Docker and declared in the `volumes:` section of `docker-compose.yml`. It appears in `docker volume ls` and `docker volume inspect`. Named volumes are the recommended approach for persistent data.

In this project, two named volumes are declared for persistent data: one for the WordPress database (`mariadb`) and one for the WordPress website files (`wordpress`). Both store their data under `/home/dimitri/data/` on the host machine.

---

## Architecture

```
                          Internet
                             │
                         HTTPS :443
                             │
                    ┌────────▼────────┐
                    │      NGINX      │  ← sole entry point
                    │   TLSv1.2/1.3   │    self-signed certificate
                    └──────┬──────┬───┘
                           │      │ reverse proxy
                     :9000 │      └───────────────────────────────┐
                    ┌──────▼────────┐                   ┌─────────▼────────┐
                    │   WordPress   │                   │       n8n        │
                    │   PHP-FPM     │◄──── Redis        │   automation     │
                    └──────┬────────┘      (cache)      └──────────────────┘
                     :3306 │
                    ┌──────▼────────┐
                    │    MariaDB    │
                    └───────────────┘

  Named volumes:
    mariadb   → /home/dimitri/data/mariadb
    wordpress → /home/dimitri/data/wordpress
    n8n       → /home/dimitri/data/n8n

  Bonus services (accessible from outside):
    :8080 → website   (static site)
    :8081 → adminer   (database UI)
    :21   → FTP       (access to WordPress volume)
```

All containers belong to the `inception` bridge network.

---

## Services

### Mandatory

| Service     | Role                     | Technical details                                        |
|-------------|--------------------------|----------------------------------------------------------|
| `nginx`     | HTTPS reverse proxy      | TLSv1.2/1.3 only, port 443, self-signed certificate     |
| `wordpress` | CMS                      | PHP-FPM on port 9000, **no built-in web server**        |
| `mariadb`   | Database                 | 2 users: admin (not named "admin") + author role        |

WordPress is configured without NGINX because the subject requires separation of concerns: NGINX handles TLS and HTTP routing, while WordPress only processes PHP via FastCGI. NGINX forwards `.php` requests using `fastcgi_pass wordpress:9000`.

### Bonus

| Service   | Role                                          | Access                          |
|-----------|-----------------------------------------------|---------------------------------|
| `redis`   | WordPress object cache (redis-cache plugin)   | Internal only                   |
| `ftp`     | FTP access to the WordPress volume (vsftpd)   | Port 21 + 21100-21110 (passive) |
| `adminer` | Web-based database management UI              | http://dinguyen.42.fr:8081      |
| `website` | Static site (HTML/CSS, no PHP)                | http://dinguyen.42.fr:8080      |
| `n8n`     | Workflow automation tool (free-choice service)| https://n8n.dinguyen.42.fr      |

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed on the VM
- Add the following entries to `/etc/hosts`:
  ```
  127.0.0.1  dinguyen.42.fr
  127.0.0.1  n8n.dinguyen.42.fr
  ```
- Create the `srcs/.env` file from the provided template:
  ```bash
  cp srcs/.env.example srcs/.env
  # then edit with real values
  ```

### Environment variables (`.env`)

| Variable              | Description                                         |
|-----------------------|-----------------------------------------------------|
| `DOMAIN_NAME`         | Domain name (e.g. `dinguyen.42.fr`)                 |
| `MYSQL_DATABASE`      | WordPress database name                             |
| `MYSQL_USER`          | MariaDB user for WordPress                          |
| `MYSQL_PASSWORD`      | MariaDB user password                               |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password                               |
| `WP_ADMIN_USER`       | WordPress admin login (must not contain "admin")    |
| `WP_ADMIN_PASSWORD`   | WordPress admin password                            |
| `WP_ADMIN_EMAIL`      | WordPress admin email                               |
| `WP_USER`             | Second WordPress user (author role)                 |
| `WP_USER_PASSWORD`    | Second user password                                |
| `WP_USER_EMAIL`       | Second user email                                   |
| `FTP_USER`            | FTP username                                        |
| `FTP_PASSWORD`        | FTP password                                        |

### Usage

```bash
make          # Creates data directories, builds and starts all containers
make down     # Stops containers (volumes are preserved)
make re       # Recreates containers without losing data (forces rebuild)
make clean    # Stops containers and removes Docker volumes
make fclean   # Full cleanup: images, volumes, Docker cache
```

### First-run initialization

On first startup, the init scripts handle configuration automatically:

- **MariaDB**: creates the database and users from environment variables.
- **WordPress**: waits for MariaDB to be ready (polls `mysqladmin ping`), downloads WordPress, configures `wp-config.php`, installs the CMS via WP-CLI, creates both users, installs and enables the Redis plugin.
- **Redis**: configured as WordPress object cache (`WP_REDIS_HOST=redis`, port 6379).

Initialization is **idempotent**: if `wp-config.php` already exists, the script skips installation.

---

## Project Structure

```
.
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env                    ← to create (ignored by git)
    ├── .env.example            ← template provided
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/          ← SSL certificate generation
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/init.sh   ← WP + Redis installation via WP-CLI
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/init.sh
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── website/
            └── n8n/
```

---

## Resources

### Documentation

- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WP-CLI documentation](https://wp-cli.org/)
- [Redis documentation](https://redis.io/docs/)
- [vsftpd documentation](https://security.appspot.com/vsftpd.html)
- [n8n documentation](https://docs.n8n.io/)

### Video tutorials

- [cocadmin — Docker pour les débutants (YouTube)](https://www.youtube.com/@cocadmin) — used to understand Docker fundamentals, container networking, and docker-compose structure. Particularly helpful for understanding PID 1 behavior and the difference between images and containers.

### AI usage

AI tools were used in the following ways during this project:

- Finding relevant learning resources and getting familiar with essential Docker commands during the early stages.
- Generating the `USER_DOC.md` and `DEV_DOC.md` documentation files, which were then reviewed and corrected to match the actual project configuration.
- Generating the initial structure of the static website (`srcs/requirements/bonus/website/tools/index.html`), which was then adjusted and validated manually.
