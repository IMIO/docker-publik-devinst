# Prérequis
Ajouter dans le /etc/hosts

`127.0.0.1 agent-combo.dev.publik.love authentic.dev.publik.love bijoe.dev.publik.love chrono.dev.publik.love combo.dev.publik.love fargo.dev.publik.love hobo.dev.publik.love passerelle.dev.publik.love wcs.dev.publik.love lingo.dev.publik.love`

# Usage
Construire : 
`docker compose up -d --build`

Suivre les logs :
`docker logs -f publik-dev`

Arrêter :
`docker compose stop`

Démarrer :
`docker compose start`

Une fois le build terminé, lancer la commande de suivi de log pour voir le make install et make deploy. Une fois les services démarrés `wcs entered RUNNING state, process has stayed up for > than 10 seconds (startsecs)` vous pouvez aller sur `https://combo.dev.publik.love/manage/`

# Librairie dans Pycharm
## Lier la venv
La venv est créée dans le conteneur (Debian 13, Python 3.13). Ses liens `python3`/`python3.13` pointent vers `/usr/bin/python3` du conteneur : sur l'hôte, ce binaire doit aussi être en 3.13, sinon le `site-packages` de la venv (`lib/python3.13/`) n'est pas trouvé et PyCharm ne reconnaît pas django, requests, etc.
### Vérifier la version de python de la venv
`ls /home/path/to/docker-publik-devinst/data/envs/publik-env-py3/lib/`

Le nom du dossier (`python3.13`, `python3.11`…) donne la version attendue par la venv. Les liens présents dans `bin/` se vérifient avec :

`ls -l /home/path/to/docker-publik-devinst/data/envs/publik-env-py3/bin/python*`

Adapter la version dans les commandes ci-dessous si elle diffère de 3.13.
### Vérifier la version de python de l'hôte
`/usr/bin/python3 --version`
`which python3.13`
### Installer Python 3.13 (si absent)
`sudo add-apt-repository ppa:deadsnakes/ppa`
`sudo apt update`
`sudo apt install python3.13`
### Lier la venv à la version de python
`ln -sf /usr/bin/python3.13 /home/path/to/docker-publik-devinst/data/envs/publik-env-py3/bin/python3.13`

Sans impact sur le conteneur : Debian 13 fournit aussi `/usr/bin/python3.13`.
### Configurer l'interpréteur
Dans Pycharm : Settings → Project → Python Interpreter → Add Interpreter → Add Local Interpreter → Virtualenv Environment → Existing, puis choisir `/home/path/to/docker-publik-devinst/data/envs/publik-env-py3/bin/python3.13`
## Ajouter les sources
Dans Settings → Project → Project Structure → Add Content Root
Ajouter `/home/path/to/docker-publik-devinst/data/src/passerelle` et le marquer comme Sources (passerelle est installé en éditable avec des chemins du conteneur, non résolus depuis l'hôte).

En cas de doute après changement d'interpréteur : File → Invalidate Caches.

# Créer une passerelle
## Installation mode éditable
`docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python -m pip install -e /home/publik/src/DOSSIER_PASSERELLE`
## Settings
Dans `/home/path/to/docker-publik-devinst/data/config/publik/settings/passerelle/settings.d/` ajouter
```python
INSTALLED_APPS += ('passerelle_imio_...',)
TENANT_APPS += ('passerelle_imio_...',)
```
## Créer les migrations
`docker exec publik-dev /home/publik/envs/publik-env-py3/bin/passerelle-manage makemigrations passerelle_imio_...`

## Exécuter les migrations
`docker exec publik-dev /home/publik/envs/publik-env-py3/bin/passerelle-manage migrate_schemas`

## Redémarrer passerelle
`docker exec publik-dev sudo supervisorctl restart django:passerelle`

# Bug
## Le menu n'apparait pas correctement dans certaine brique
dans la console du navigateur
`localStorage.removeItem('gadjo_sidebar_menu')`
Puis rechargez la page.
