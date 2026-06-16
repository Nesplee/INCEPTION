# Spec — `correction_live.sh` : entraînement interactif à la correction Inception

**Date :** 2026-06-16
**Auteur :** dinguyen (avec Claude)
**Statut :** validé, prêt pour plan d'implémentation

## Contexte

Le repo contient déjà `CORRECTION_GUIDE.md` (guide statique avec commandes) et 4 captures
d'écran de la grille d'évaluation officielle 42 (`Capture d'écran du 2026-05-24 20-45-*.png`).
Une correction a déjà été ratée. L'objectif est un script qui permet de **s'entraîner seul**,
en se mettant dans les conditions du jour J, en suivant l'ordre exact de la grille officielle,
sans rien sauter par oubli.

## Objectif

Un script bash autonome, `correction_live.sh`, à la racine du repo, qui fait dérouler
**tous** les points de contrôle de la grille officielle (capturée dans les screenshots) dans
l'ordre exact, avec pour chaque point soit une commande à exécuter soi-même, soit une question
orale à préparer, soit une vérification visuelle dans le navigateur — et qui termine sur un
récapitulatif des points en échec à revoir.

## Hors-scope

- Pas d'exécution automatique des commandes (le script affiche, l'utilisateur exécute lui-même
  dans un autre terminal, conformément au choix déjà validé).
- Pas de parsing de `CORRECTION_GUIDE.md` ni des PDF/images au runtime — toutes les données
  (textes officiels + commandes pratiques) sont codées en dur dans le script, extraites une
  fois pour toutes à la rédaction de cette spec.
- Pas de simulation des actions de l'évaluateur (changement de port aléatoire) — l'étape 10
  affiche l'exemple du guide (port 8080→8082) mais ne le choisit pas dynamiquement.
- Pas de persistance entre sessions (pas d'historique des scores précédents).

## Architecture

Un seul fichier `correction_live.sh`, structuré en 3 parties :

1. **Données** : un tableau bash `STEPS` où chaque step est une entrée sérialisée (voir format
   ci-dessous). Toutes les données viennent des 4 captures d'écran (critères officiels
   eliminatoires "Yes/No") + `CORRECTION_GUIDE.md` (commandes pratiques et explications orales).
2. **Moteur** : fonctions `run_step()`, `ask_validation()`, `show_menu()`, `show_summary()`.
3. **Point d'entrée** : menu de démarrage puis boucle sur les steps sélectionnés.

### Format d'une step

Chaque step est un bloc avec :
- `id` : identifiant court (ex: `prelim`, `general`, `mandatory_readme`)
- `title` : titre affiché (ex: "ÉTAPE 1 — Preliminary Tests")
- `eliminatory` : `true`/`false` — si `true`, un échec affiche un avertissement "⚠ ÉLIMINATOIRE"
  dans le récap final
- `criteria[]` : liste des critères officiels (texte des screenshots, en anglais, tels qu'écrits
  sur la grille) — affichés tels quels comme rappel de ce qui est jugé
- `commands[]` : liste de commandes shell à afficher (l'utilisateur les exécute lui-même dans un
  autre terminal)
- `oral[]` : liste de questions orales à se poser à voix haute (avec un corrigé court affichable
  à la demande, tiré de `CORRECTION_GUIDE.md`)
- `manual_check` : texte d'une vérification visuelle/navigateur si applicable (pas de commande)

Après affichage de tout le contenu d'une step, le script demande :
`[o] OK / [e] Échec / [s] Skip / [r] Revoir le corrigé (si oral)`
et enregistre le résultat dans un tableau de résultats pour le récap final.

### Séquence des steps (ordre exact de la grille officielle)

1. **AVANT LA CORRECTION** — checklist de préparation (non-officielle, mais critique : `.env`
   présent, dossiers data existants, `/etc/hosts`, `docker ps` vide) — *non éliminatoire, juste
   un rappel de prépa*
2. **Preliminary Tests** *(éliminatoire)* — 4 critères officiels :
   - usage d'un `.env` local et/ou de secrets Docker autorisé ; tout credential/clé/mot de passe
     ailleurs dans le repo ou hors fichiers de secrets → arrêt, note 0
   - le binôme/évalué doit être présent
   - si aucun travail rendu / mauvais fichiers / mauvais dossier / mauvais nom → note 0, fin
   - le dépôt git doit être cloné sur la machine de l'évaluateur
   - Commandes pratiques : `git log --all --oneline -- srcs/.env`, `cat .gitignore`
3. **General Instructions** *(éliminatoire)* — tous les critères officiels listés (aide de
   l'évalué si besoin, `srcs/` à la racine, `Makefile` à la racine, commande de nettoyage complet
   exécutée par l'évaluateur, suppression de `/home/<login>/data/*`, pas de `network: host` ni
   `links:`, présence de `networks:`, pas de `--link`, pas de boucle infinie/`tail -f`/
   `sleep infinity` dans les Dockerfiles, pas de lancement en background type `nginx & bash`,
   images construites depuis Alpine/Debian pénultième stable) + toutes les commandes grep
   correspondantes du guide + `make`.
4. **Mandatory Part — Activity Overview** *(non éliminatoire mais notée)* — 4 questions orales
   avec corrigé masqué par défaut (Docker/Compose, image avec/sans Compose, Docker vs VM,
   structure de répertoire) — critère officiel : "the evaluated learner has to explain in his
   own terms the following items: how Docker and docker compose work, the difference between
   a Docker image used with docker-compose and without, the benefit of Docker compared to VMs,
   the pertinence of the directory structure required for this project".
5. **Mandatory Part — README check** *(non éliminatoire)* — critères officiels (README.md
   présent à la racine, doit suivre le format demandé — Description/Instructions/Resources,
   IA mentionnée si utilisée) + commandes `cat README.md`, `head -1 README.md`.
6. **Mandatory Part — Documentation check** *(non éliminatoire)* — critères officiels
   (USER_DOC.md et DEV_DOC.md présents à la racine, USER_DOC doit fournir des instructions
   d'usage basique, DEV_DOC doit fournir les prérequis dev) + commandes `ls`/`cat`.
7. **Mandatory Part — Simple setup** *(éliminatoire)* — critères officiels (port 443 seul
   accessible, certificat SSL/TLS présent, page WordPress affichée et non la page
   d'installation, login admin sans "admin") + commandes curl HTTP/HTTPS + vérif manuelle
   navigateur.
8. **Docker Basics** *(éliminatoire)* — critères officiels (un Dockerfile par service, non
   vide, écrit par l'évalué — pas d'image prête/DockerHub, base Alpine/Debian pénultième stable
   uniquement, nom d'image = nom du service, lancé via docker compose sans crash) + commandes
   `ls`, `wc -l`, `docker images`, `grep FROM`, `docker compose ps`.
9. **Docker Network** *(éliminatoire)* — critères officiels (réseau docker-network visible via
   `docker network ls`, explication orale du fonctionnement attendue) + commande
   `docker network inspect` + question orale avec corrigé.
10. **NGINX avec SSL/TLS** *(éliminatoire)* — critères officiels (Dockerfile présent, conteneur
    créé, port 80 inaccessible, page WordPress affichée sur `https://login.42.fr`, certificat
    TLS v1.2/1.3 démontré — auto-signé accepté) + commandes curl port 80/443, test TLS 1.2/1.3,
    `cat nginx.conf`.
11. **WordPress + php-fpm** *(non capturée dans les screenshots mais présente dans le sujet et
    le guide — gardée car éliminatoire-like)* — critères du guide (pas de nginx dans le
    conteneur wordpress, php-fpm actif, site affiché et configuré, admin sans "admin" dans le
    login) + commandes `docker exec wordpress which nginx`, `wp user list`.
12. **MariaDB** — commandes `mysqladmin ping`, `SHOW DATABASES`, `docker port mariadb` (doit
    être vide — pas de port exposé).
13. **Volumes** — commandes `docker volume ls`, `docker volume inspect`, vérif des fichiers
    persistés sous `/home/<login>/data/`.
14. **Configuration modification (test en live)** *(éliminatoire)* — critère officiel : "During
    the defense, the reviewer must ask the evaluated person to modify the configuration of one
    service (for example by changing the port it is using). After the change, the evaluated
    person must rebuild and functional with the new configuration. If the modification cannot
    be performed or the service no longer works, the evaluation ends now." — déroulé en 4
    sous-étapes reprenant l'exemple du guide (modifier le port du `website` 8080→8082,
    `make re`, vérifier ancien port mort / nouveau port répond, vérifier dans le navigateur).
15. **Bonus** *(non noté si la partie obligatoire n'est pas parfaite — rappel affiché)* — une
    sous-step par bonus (Redis, FTP, Adminer, Static website, n8n), chacune avec ses commandes
    de vérif + explication orale à préparer, tirées du guide. Le critère officiel de la grille
    est rappelé : "Set up a service of your choice that you think is useful... Ask test and
    require justification of how it works and why they believe it is useful."
16. **Rating & flags (récap final)** — pas une vraie step interactive, mais un écran de
    rappel affiché en clôture : la note évaluateur va de 0 à 5 (échec) à 5 (excellent), et les
    flags possibles doivent être cochés mentalement par l'utilisateur en s'auto-évaluant :
    Ok / Empty work / Incomplete work / Cheat / Outstanding project / Crash /
    Concerning situation — affichés comme pense-bête, pas comme question.

### Menu de démarrage

```
=== Entraînement correction Inception ===
[1] Parcours complet (toutes les étapes, dans l'ordre)
[2] Choisir une section précise
[q] Quitter
```

Si `[2]` : liste numérotée des 16 steps ci-dessus, sélection libre, retour au menu après la
section choisie.

Pendant le parcours linéaire, taper `s` à tout moment passe à la step suivante sans validation
(uniquement consigné comme "skip" dans le récap, pas comme échec).

### Couleurs / UX

Codes ANSI : vert (`\033[32m`) pour OK, rouge (`\033[31m`) pour échec, jaune (`\033[33m`) pour
skip/avertissement éliminatoire, gras pour les titres de step. Fonction `color()` centralisée.

### Récapitulatif final

À la fin du parcours (ou en quittant) :

```
=== RÉCAPITULATIF ===
✓ OK      : 9 étapes
✗ Échec   : 2 étapes  → WordPress + php-fpm, NGINX SSL/TLS
⊘ Skip    : 1 étape   → Bonus n8n

⚠ Étapes ÉCHEC marquées éliminatoires dans la grille officielle :
  - NGINX avec SSL/TLS

Revois en priorité : WordPress + php-fpm, NGINX avec SSL/TLS
```

Le compte "échoué" inclut un avertissement spécial si la step était `eliminatory: true`,
car dans la vraie correction un seul échec éliminatoire = fin de l'évaluation.

## Erreurs / cas limites

- Ctrl+C à tout moment : afficher le récap partiel avant de quitter (trap `SIGINT`).
- Terminal sans couleur (`TERM=dumb` ou non-tty) : détecter et désactiver les couleurs ANSI.
- Aucune dépendance externe : bash pur (pas de `jq`, pas de `python3`).

## Tests

Comme c'est un script interactif sans logique métier complexe à isoler, la vérification se fera
manuellement (pas de TDD applicable ici) :
- lancer le parcours complet, répondre `o` à tout, vérifier le récap "tout OK"
- relancer, répondre `e` à une step éliminatoire, vérifier l'avertissement dans le récap
- tester le menu de sélection de section
- tester Ctrl+C en cours de route
