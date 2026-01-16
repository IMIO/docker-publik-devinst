# Prérequis
Ajouter dans le /etc/hosts

`127.0.0.1 agent-combo.dev.publik.love authentic.dev.publik.love bijoe.dev.publik.love chrono.dev.publik.love combo.dev.publik.love fargo.dev.publik.love hobo.dev.publik.love passerelle.dev.publik.love wcs.dev.publik.love`

# Usage
Construire : 
`docker compose up -d --build`

Suivre les logs :
`docker logs -f publik-dev`

Arrêter :
`docker compose stop`

Démarrer :
`docker compose start`

Une fois le build terminé, lancer la commande de suivi de log pour voir le make install et make deploy. Une fois les service démarré `wcs entered RUNNING state, process has stayed up for > than 10 seconds (startsecs)` vous pouvez aller sur `https://combo.dev.publik.love/manage/`
