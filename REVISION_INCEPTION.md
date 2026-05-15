# Révision Inception

## Différence entre bind mount et volume

### Question
Quelle différence entre **bind mount** et **volume** ?

### Réponse courte
- **Bind mount** : on monte directement un dossier précis de l'hôte dans le conteneur.
- **Volume Docker** : Docker gère le stockage et le montage.

### Réponse plus précise
- Avec un **bind mount**, tu choisis explicitement le chemin côté machine hôte, par exemple `/home/dimitri/data/wordpress`.
- Avec un **volume Docker classique**, Docker stocke les données dans son propre espace, souvent sous `/var/lib/docker/volumes/...`, sans que tu manipules directement le chemin réel.

### Cas de ce repo
Dans `/home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml`, ce projet utilise des **volumes nommés Docker** configurés avec :
- `driver: local`
- `driver_opts`
- `o: bind`
- `device: /home/dimitri/data/...`

Donc ici, ce n'est pas un bind mount "brut" écrit directement dans la section `services` comme :

```yaml
- /home/dimitri/data/wordpress:/var/www/html/wordpress
```

À la place, ce sont des **volumes Docker qui pointent vers des dossiers précis de l'hôte**.

### Formulation orale simple
"Dans mon projet, j'utilise des volumes Docker nommés, mais ils sont configurés pour s'appuyer sur des dossiers précis de l'hôte grâce à l'option bind. Donc Docker garde la logique de volume, mais les données sont physiquement stockées dans `/home/dimitri/data/...`."

### Dossiers utilisés ici
- `/home/dimitri/data/mariadb`
- `/home/dimitri/data/wordpress`
- `/home/dimitri/data/n8n`

---

## Questions théoriques avec réponses

### 1. Qu'est-ce que Docker ?
Docker est un outil de conteneurisation qui permet d'exécuter une application avec ses dépendances dans un environnement isolé et reproductible.

### 2. Différence entre une image et un conteneur ?
- **Image** : modèle immuable construit à partir d'un Dockerfile.
- **Conteneur** : instance en cours d'exécution d'une image.

### 3. Qu'est-ce qu'un Dockerfile ?
C'est le fichier qui décrit comment construire une image Docker : image de base, paquets, fichiers copiés, configuration et commande de lancement.

### 4. Pourquoi plusieurs conteneurs au lieu d'un seul ?
Parce qu'on sépare les responsabilités :
- NGINX sert le trafic HTTPS
- WordPress exécute PHP-FPM
- MariaDB stocke les données

### 5. Pourquoi utiliser Docker Compose ?
Parce qu'il permet de lancer plusieurs services ensemble avec leurs réseaux, volumes, variables d'environnement et dépendances.

### 6. Qu'est-ce qu'un volume ?
Un volume permet de conserver les données même si le conteneur est supprimé ou recréé.

### 7. Pourquoi les volumes sont importants dans Inception ?
Parce qu'ils assurent la persistance des données WordPress, MariaDB et n8n.

### 8. Pourquoi NGINX ?
NGINX est le point d'entrée du site. Il écoute en HTTPS et transmet les requêtes PHP à WordPress via FastCGI.

### 9. Pourquoi WordPress tourne avec PHP-FPM ?
Parce que NGINX ne traite pas PHP lui-même. PHP-FPM exécute les scripts PHP pour WordPress.

### 10. Pourquoi MariaDB ?
MariaDB stocke les données du site : utilisateurs, articles, pages et configuration.

### 11. Comment les conteneurs communiquent-ils entre eux ?
Grâce au réseau Docker Compose. Ils se joignent par leur nom de service, par exemple `mariadb`, `wordpress` ou `redis`.

### 12. Pourquoi ne pas utiliser localhost entre conteneurs ?
Parce que `localhost` dans un conteneur désigne ce conteneur lui-même. Pour joindre un autre service, il faut utiliser son nom sur le réseau Docker.

### 13. À quoi sert `depends_on` ?
Il définit l'ordre de démarrage, mais ne garantit pas qu'un service soit réellement prêt.

### 14. Comment WordPress attend MariaDB dans ce repo ?
Dans `/home/runner/work/INCEPTION/INCEPTION/srcs/requirements/wordpress/tools/init.sh`, WordPress boucle sur `mysqladmin ping -h mariadb` jusqu'à ce que MariaDB réponde.

### 15. Comment MariaDB est-elle initialisée ?
Dans `/home/runner/work/INCEPTION/INCEPTION/srcs/requirements/mariadb/tools/init.sh`, le script crée la base, l'utilisateur applicatif, donne les privilèges et configure le mot de passe root.

### 16. Pourquoi un script d'initialisation ?
Pour automatiser le premier démarrage : préparation de la base, installation de WordPress, création des utilisateurs et activation des bonus.

### 17. Pourquoi HTTPS est obligatoire ?
Parce que le trafic entre le client et le serveur doit être chiffré, et le sujet demande TLS.

### 18. Quels ports sont exposés dans ce projet ?
- `443` pour NGINX
- `8080` pour le site bonus
- `8081` pour Adminer
- `21` et `21100-21110` pour FTP

### 19. Quel est le rôle de Redis ?
Redis sert de cache pour WordPress afin de réduire les accès à la base et améliorer les performances.

### 20. Quel est le rôle d'Adminer ?
Adminer fournit une interface web pour consulter et administrer la base MariaDB.

### 21. Quel est le rôle de FTP ?
FTP permet d'accéder aux fichiers WordPress présents dans le volume partagé.

### 22. Que signifie `restart: unless-stopped` ?
Le conteneur redémarre automatiquement sauf s'il a été arrêté manuellement.

### 23. Pourquoi éviter `latest` ?
Parce que cette balise n'assure pas un environnement stable ni reproductible.

### 24. Pourquoi ne pas utiliser des images toutes faites ?
Parce que le sujet demande de construire tes propres images et de comprendre leur configuration.

### 25. Que se passe-t-il si on supprime un conteneur ?
Le conteneur disparaît, mais les données restent si elles sont stockées dans un volume.

### 26. Que se passe-t-il si on supprime aussi les volumes ?
On perd les données persistées, notamment la base MariaDB et les fichiers WordPress.

---

## Questions pratiques avec commandes

### 1. Lancer le projet
```bash
cd /home/runner/work/INCEPTION/INCEPTION
make
```

### 2. Arrêter le projet
```bash
cd /home/runner/work/INCEPTION/INCEPTION
make down
```

### 3. Reconstruire le projet
```bash
cd /home/runner/work/INCEPTION/INCEPTION
make re
```

### 4. Supprimer les conteneurs et volumes du projet
```bash
cd /home/runner/work/INCEPTION/INCEPTION
make clean
```

### 5. Nettoyer encore plus Docker
```bash
cd /home/runner/work/INCEPTION/INCEPTION
make fclean
```

### 6. Voir les conteneurs en cours
```bash
docker ps
```

### 7. Voir les images
```bash
docker images
```

### 8. Voir les services du compose
```bash
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml ps
```

### 9. Voir les logs de tous les services
```bash
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml logs
```

### 10. Voir les logs d'un service
```bash
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml logs nginx
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml logs wordpress
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml logs mariadb
```

### 11. Entrer dans le conteneur NGINX
```bash
docker exec -it nginx sh
```

### 12. Entrer dans le conteneur WordPress
```bash
docker exec -it wordpress sh
```

### 13. Entrer dans le conteneur MariaDB
```bash
docker exec -it mariadb sh
```

### 14. Entrer dans le conteneur Redis
```bash
docker exec -it redis sh
```

### 15. Vérifier que le HTTPS fonctionne
```bash
curl -k https://localhost
```

### 16. Vérifier le certificat TLS
```bash
openssl s_client -connect localhost:443
```

### 17. Voir les volumes Docker
```bash
docker volume ls
```

### 18. Inspecter un volume précis
D'abord :
```bash
docker volume ls
```

Puis inspecter le nom exact affiché :
```bash
docker volume inspect <nom_du_volume>
```

### 19. Voir les réseaux Docker
```bash
docker network ls
```

### 20. Inspecter le réseau du projet
D'abord :
```bash
docker network ls
```

Puis :
```bash
docker network inspect <nom_du_reseau>
```

### 21. Inspecter un conteneur
```bash
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### 22. Vérifier que NGINX écoute sur 443
```bash
docker exec -it nginx sh
ss -tulpn
```

### 23. Afficher la configuration NGINX du repo
```bash
cat /home/runner/work/INCEPTION/INCEPTION/srcs/requirements/nginx/conf/nginx.conf
```

### 24. Vérifier que WordPress lance PHP-FPM
```bash
docker exec -it wordpress sh
ps aux
```

### 25. Vérifier que WordPress peut joindre MariaDB
```bash
docker exec -it wordpress sh
mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"
```

### 26. Se connecter à MariaDB
```bash
docker exec -it mariadb mysql -u root -p
```

### 27. Afficher les bases de données
```bash
docker exec -it mariadb mysql -u root -p -e "SHOW DATABASES;"
```

### 28. Afficher les utilisateurs MariaDB
```bash
docker exec -it mariadb mysql -u root -p -e "SELECT user,host FROM mysql.user;"
```

### 29. Voir les utilisateurs WordPress
```bash
docker exec -it wordpress wp user list --allow-root --path=/var/www/html/wordpress
```

### 30. Voir les plugins WordPress
```bash
docker exec -it wordpress wp plugin list --allow-root --path=/var/www/html/wordpress
```

### 31. Afficher la configuration WordPress
```bash
docker exec -it wordpress sh
cat /var/www/html/wordpress/wp-config.php
```

### 32. Vérifier que Redis fonctionne
```bash
docker exec -it redis redis-cli ping
```

Réponse attendue :
```bash
PONG
```

### 33. Montrer la persistance des données
Créer un fichier de test :
```bash
docker exec -it wordpress sh
touch /var/www/html/wordpress/test_persistence
```

Recréer ensuite les conteneurs sans supprimer les volumes, puis vérifier :
```bash
docker exec -it wordpress ls -la /var/www/html/wordpress
```

### 34. Afficher le fichier compose
```bash
cat /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml
```

### 35. Afficher les scripts d'initialisation principaux
```bash
cat /home/runner/work/INCEPTION/INCEPTION/srcs/requirements/wordpress/tools/init.sh
cat /home/runner/work/INCEPTION/INCEPTION/srcs/requirements/mariadb/tools/init.sh
```

---

## Questions pièges fréquentes

### Pourquoi `depends_on` ne suffit pas ?
Parce qu'il garantit l'ordre de démarrage, pas le fait qu'un service soit prêt à accepter des connexions.

### Pourquoi utiliser `exec` à la fin d'un script d'init ?
Pour remplacer le shell par le vrai processus principal du conteneur et mieux gérer les signaux.

### Pourquoi un seul service principal par conteneur ?
Parce que c'est la philosophie Docker : un conteneur doit avoir une responsabilité claire.

### Pourquoi partager les fichiers WordPress entre NGINX, WordPress et FTP ?
Parce que ces services doivent accéder aux mêmes fichiers du site.

### Pourquoi utiliser un réseau bridge ?
Parce qu'il permet aux conteneurs du projet de communiquer entre eux tout en restant isolés.

### Pourquoi exposer 443 et pas 80 ?
Parce que le sujet demande un accès sécurisé en HTTPS/TLS.

---

## Mini présentation orale

### Présentation rapide du projet
"Mon projet Inception déploie une infrastructure Docker multi-conteneurs. J'ai séparé NGINX, WordPress et MariaDB dans des conteneurs distincts, reliés par un réseau Docker. Les données sont persistées avec des volumes, et l'accès au site se fait en HTTPS via NGINX."

### Présentation rapide de NGINX
"NGINX est le point d'entrée du site. Il écoute sur le port 443 en TLS et transmet les requêtes PHP à PHP-FPM dans le conteneur WordPress."

### Présentation rapide de WordPress
"WordPress contient l'application PHP. Au premier démarrage, le script d'initialisation télécharge WordPress, prépare la configuration, attend MariaDB, puis installe le site et crée les utilisateurs."

### Présentation rapide de MariaDB
"MariaDB est la base de données du projet. Son script d'initialisation crée la base, l'utilisateur applicatif et configure les privilèges."

---

## Liste courte à pratiquer

```bash
cd /home/runner/work/INCEPTION/INCEPTION
make
make down
make re
make clean
make fclean
docker ps
docker images
docker volume ls
docker network ls
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml ps
docker-compose -f /home/runner/work/INCEPTION/INCEPTION/srcs/docker-compose.yml logs
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
curl -k https://localhost
openssl s_client -connect localhost:443
docker exec -it redis redis-cli ping
docker exec -it wordpress wp user list --allow-root --path=/var/www/html/wordpress
docker exec -it wordpress wp plugin list --allow-root --path=/var/www/html/wordpress
docker exec -it mariadb mysql -u root -p
```
