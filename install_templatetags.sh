#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_SRC="${SCRIPT_DIR}/data/src"
TEMPLATETAGS_SRC="${HOST_SRC}/imio-teleservices-templatetags"
CONTAINER_TEMPLATETAGS_SRC="/home/publik/src/imio-teleservices-templatetags"
WCS_SETTINGS_D="${SCRIPT_DIR}/data/config/publik/settings/wcs/settings.d"

# Clone sur le host (HTTPS)
test -d "${TEMPLATETAGS_SRC}" || git clone https://git.entrouvert.org/entrouvert/imio-teleservices-templatetags.git "${TEMPLATETAGS_SRC}"

# Installation en mode éditable dans le container
docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python -m pip install -e "${CONTAINER_TEMPLATETAGS_SRC}"

# Création du fichier templates.py dans les settings de wcs
mkdir -p "${WCS_SETTINGS_D}"
echo "TEMPLATES[0]['OPTIONS']['builtins'].append('imio_teleservices_templatetags.templatetags.imio_teleservices')" > "${WCS_SETTINGS_D}/templates.py"

# Redémarrage de wcs
docker exec publik-dev sudo supervisorctl restart django:wcs
