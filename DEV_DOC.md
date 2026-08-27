# Developer Documentation

## Prerequisites

- Docker and Docker Compose installed
- Add to `/etc/hosts`:
  ```
  127.0.0.1  dinguyen.42.fr
  127.0.0.1  n8n.dinguyen.42.fr
  ```

## Setup

```bash
cp srcs/.env.example srcs/.env
# edit srcs/.env with real values
make
```

The `make` command creates the data directories, builds all images, and starts all containers.

## Environment variables (`srcs/.env`)

| Variable              | Description                                  |
|-----------------------|----------------------------------------------|
| `DOMAIN_NAME`         | `dinguyen.42.fr`                             |
| `MYSQL_DATABASE`      | Database name                                |
| `MYSQL_USER`          | MariaDB user                                 |
| `MYSQL_PASSWORD`      | MariaDB user password                        |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password                        |
| `WP_ADMIN_USER`       | WordPress admin (must not contain "admin")   |
| `WP_ADMIN_PASSWORD`   | WordPress admin password                     |
| `WP_ADMIN_EMAIL`      | WordPress admin email                        |
| `WP_USER`             | Second WordPress user (author)               |
| `WP_USER_PASSWORD`    | Second user password                         |
| `WP_USER_EMAIL`       | Second user email                            |
| `FTP_USER`            | FTP username                                 |
| `FTP_PASSWORD`        | FTP password                                 |

## Makefile

| Command      | Effect                                      |
|--------------|---------------------------------------------|
| `make`       | Build and start all containers              |
| `make down`  | Stop containers (data preserved)            |
| `make re`    | Rebuild and restart (data preserved)        |
| `make clean` | Stop + remove volumes (data lost)           |
| `make fclean`| Full cleanup: images, volumes, cache        |

## Data storage

Named volumes are stored on the host under `/home/dinguyen/data/`:

| Volume      | Host path                     | Used by   |
|-------------|-------------------------------|-----------|
| `mariadb`   | `/home/dinguyen/data/mariadb`  | MariaDB   |
| `wordpress` | `/home/dinguyen/data/wordpress`| WordPress |
| `n8n`       | `/home/dinguyen/data/n8n`      | n8n       |

Data survives `make down` and `make re`. It is deleted by `make clean` and `make fclean`.

## Useful commands

```bash
docker ps                      # list running containers
docker logs <name>             # view logs
docker exec -it <name> bash    # open a shell inside a container
docker volume ls               # list volumes
```
