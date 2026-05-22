# User Documentation

## Services

| Service   | URL                              |
|-----------|----------------------------------|
| WordPress | https://dinguyen.42.fr           |
| Adminer   | http://dinguyen.42.fr:8081       |
| Website   | http://dinguyen.42.fr:8080       |
| n8n       | https://n8n.dinguyen.42.fr       |
| FTP       | ftp://dinguyen.42.fr (port 21)   |

## Start / Stop

```bash
make        # start everything
make down   # stop (data preserved)
make re     # rebuild and restart (data preserved)
make fclean # full cleanup (data lost)
```

## Credentials

All credentials are in `srcs/.env`. Edit that file to change any password.

## WordPress admin panel

Go to `https://dinguyen.42.fr/wp-admin` and log in with `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD`.

## Adminer (database UI)

- Server: `mariadb`
- User / Password: `MYSQL_USER` / `MYSQL_PASSWORD`
- Database: `MYSQL_DATABASE`

## Check that everything is running

```bash
docker ps
```

All containers should show `Up`. To see logs:

```bash
docker logs <container_name>
```
