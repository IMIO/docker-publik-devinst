#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DST="${SCRIPT_DIR}/data/src/extra_cells.py"
CONTAINER_SRC="/home/publik/src/extra_cells.py"
SETTINGS_D="/home/publik/.config/publik/settings/combo/settings.d"
SYMLINK="${SETTINGS_D}/extra_cells.py"

# Copie du fichier dans data/src (accessible dans le container via le volume)
cp "${SCRIPT_DIR}/extra_cells.py" "${HOST_DST}"

# Création du répertoire settings.d si nécessaire et lien symbolique
docker exec publik-dev bash -c "mkdir -p '${SETTINGS_D}' && test -e '${SYMLINK}' || ln -s '${CONTAINER_SRC}' '${SYMLINK}'"

# Redémarrage de combo
docker exec publik-dev sudo supervisorctl restart django:combo
