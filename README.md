# Inception

Déploiement d'une infrastructure web multi-conteneurs via Docker Compose sur une machine virtuelle.
Chaque service tourne dans son propre conteneur construit depuis un `Dockerfile` dédié — aucune image toute-faite n'est utilisée (hormis Alpine/Debian comme base).

---

## Notions clés

### Conteneur vs Machine virtuelle

Un conteneur **n'est pas une VM**. Il partage le noyau de l'hôte et isole les processus via les namespaces Linux (PID, réseau, système de fichiers). Il est plus léger et démarre en millisecondes, mais n'emule pas de matériel.

### PID 1 dans un conteneur

Dans un conteneur, le processus lancé par `CMD` ou `ENTRYPOINT` devient le **PID 1**. C'est lui qui reçoit les signaux système (`SIGTERM`, `SIGKILL`). Il ne faut pas utiliser de hacks comme `tail -f`, `sleep infinity` ou `while true` pour maintenir le conteneur en vie : le démon du service doit être lancé **en foreground** directement (ex : `exec php-fpm -F`, `exec mysqld`).

### Réseau Docker bridge

Un réseau `bridge` crée un sous-réseau virtuel isolé. Les conteneurs y communiquent par leur **nom de service** (DNS interne Docker), sans exposer de ports à l'hôte. Seul NGINX expose le port 443 vers l'extérieur.

---

## Architecture

```
                          Internet
                             │
                         HTTPS :443
                             │
                    ┌────────▼────────┐
                    │      NGINX      │  ← seul point d'entrée
                    │  TLSv1.2/1.3   │    certificat auto-signé
                    └──────┬──────┬──┘
                           │      │ reverse proxy
                     :9000 │      └───────────────────────────────┐
                    ┌──────▼────────┐                   ┌─────────▼────────┐
                    │   WordPress   │                   │       n8n        │
                    │   PHP-FPM     │◄──── Redis        │  automatisation  │
                    └──────┬────────┘      (cache)      └──────────────────┘
                     :3306 │
                    ┌──────▼────────┐
                    │    MariaDB    │
                    └───────────────┘

  Volumes persistants :
    mariadb   → /home/dimitri/data/mariadb
    wordpress → /home/dimitri/data/wordpress
    n8n       → /home/dimitri/data/n8n

  Accès bonus (hors réseau principal) :
    :8080 → website  (site statique)
    :8081 → adminer  (interface BDD)
    :21   → FTP      (accès au volume WordPress)
```

Tous les conteneurs appartiennent au réseau bridge `inception`.

---

## Services

### Partie obligatoire

| Service     | Rôle                          | Détails techniques                                      |
|-------------|-------------------------------|----------------------------------------------------------|
| `nginx`     | Reverse proxy HTTPS           | TLSv1.2/1.3 uniquement, port 443, certificat auto-signé |
| `wordpress` | CMS                           | PHP-FPM sur port 9000, **sans serveur web intégré**     |
| `mariadb`   | Base de données               | 2 utilisateurs : admin (non nommé "admin") + auteur     |

**Pourquoi WordPress sans nginx ?**
Le sujet impose la séparation des responsabilités : nginx gère le TLS et le routage HTTP, WordPress ne fait que traiter le PHP via FastCGI (protocole FPM). NGINX fait un `fastcgi_pass wordpress:9000` pour déléguer l'exécution PHP.

### Bonus

| Service   | Rôle                                         | Accès                          |
|-----------|----------------------------------------------|--------------------------------|
| `redis`   | Cache objet WordPress (plugin redis-cache)   | Interne uniquement             |
| `ftp`     | Accès FTP au volume WordPress (vsftpd)       | Port 21 + 21100-21110 (passif) |
| `adminer` | Interface web de gestion de la BDD           | http://dinguyen.42.fr:8081     |
| `website` | Site statique (HTML/CSS, sans PHP)           | http://dinguyen.42.fr:8080     |
| `n8n`     | Outil d'automatisation (service libre)       | https://n8n.dinguyen.42.fr     |

---

## Sécurité

Le sujet impose plusieurs contraintes de sécurité strictes :

- **Aucun mot de passe dans les Dockerfiles ou le code source** — toutes les credentials passent par le fichier `.env` (ignoré par git).
- **Le tag `latest` est interdit** dans les Dockerfiles — chaque image doit pointer une version précise ou une base stable (ex: `debian:bullseye`).
- **`network: host` et `--link` sont interdits** — le réseau bridge `inception` est obligatoire.
- **Les credentials ne doivent jamais être poussés sur git** — le `.env` doit figurer dans `.gitignore`.

---

## Prérequis

- Docker & Docker Compose installés sur la VM
- Ajouter les entrées suivantes dans `/etc/hosts` :
  ```
  127.0.0.1  dinguyen.42.fr
  127.0.0.1  n8n.dinguyen.42.fr
  ```
- Créer le fichier `srcs/.env` à partir du modèle :
  ```bash
  cp srcs/.env.example srcs/.env
  # puis éditer avec les vraies valeurs
  ```

### Variables d'environnement (`.env`)

| Variable           | Description                                      |
|--------------------|--------------------------------------------------|
| `DOMAIN_NAME`      | Nom de domaine (ex : `dinguyen.42.fr`)           |
| `MYSQL_DATABASE`   | Nom de la base de données WordPress              |
| `MYSQL_USER`       | Utilisateur MariaDB pour WordPress               |
| `MYSQL_PASSWORD`   | Mot de passe de l'utilisateur MariaDB            |
| `MYSQL_ROOT_PASSWORD` | Mot de passe root MariaDB                     |
| `WP_ADMIN_USER`    | Login admin WordPress (interdit : admin/Admin)   |
| `WP_ADMIN_PASSWORD`| Mot de passe admin WordPress                     |
| `WP_ADMIN_EMAIL`   | Email admin WordPress                            |
| `WP_USER`          | Second utilisateur WordPress (rôle auteur)       |
| `WP_USER_PASSWORD` | Mot de passe du second utilisateur               |
| `WP_USER_EMAIL`    | Email du second utilisateur                      |
| `FTP_USER`         | Utilisateur FTP                                  |
| `FTP_PASSWORD`     | Mot de passe FTP                                 |

---

## Utilisation

```bash
make          # Crée les dossiers de données, construit et démarre tous les conteneurs
make down     # Arrête les conteneurs (conserve les volumes)
make re       # Recrée les conteneurs sans perdre les données (force rebuild)
make clean    # Arrête les conteneurs et supprime les volumes Docker
make fclean   # Nettoyage complet : images, volumes, cache Docker
```

---

## Initialisation automatique

Au premier démarrage, les scripts d'init gèrent la configuration automatiquement :

- **MariaDB** : crée la base de données et les utilisateurs depuis les variables d'environnement.
- **WordPress** : attend que MariaDB soit disponible (poll `mysqladmin ping`), télécharge WordPress, configure `wp-config.php`, installe le CMS via `wp-cli`, crée les deux utilisateurs, installe et active le plugin Redis.
- **Redis** : configuré comme cache objet de WordPress (`WP_REDIS_HOST=redis`, port 6379).

L'initialisation est **idempotente** : si `wp-config.php` existe déjà, le script ne réinstalle rien.

---

## Données persistantes

Les volumes utilisent des **bind mounts** vers le système de fichiers de la VM :

| Volume      | Chemin sur la VM               | Contenu                   |
|-------------|--------------------------------|---------------------------|
| `mariadb`   | `/home/dimitri/data/mariadb`   | Fichiers de la base de données |
| `wordpress` | `/home/dimitri/data/wordpress` | Fichiers du site WordPress |
| `n8n`       | `/home/dimitri/data/n8n`       | Configuration et workflows n8n |

Ces dossiers sont créés automatiquement par `make`.

---

## Structure du projet

```
.
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env                  ← à créer (ignoré par git)
    ├── .env.example          ← modèle fourni
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/        ← génération du certificat SSL
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/init.sh ← installation WP + Redis via wp-cli
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
