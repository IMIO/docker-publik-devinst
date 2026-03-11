#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_D="${SCRIPT_DIR}/data/config/publik/settings/combo/settings.d"

# Copie directement dans le volume settings.d (pas besoin de symlink)
mkdir -p "${SETTINGS_D}"
cp "${SCRIPT_DIR}/extra_cells.py" "${SETTINGS_D}/extra_cells.py"

# Redémarrage de combo
docker exec publik-dev sudo supervisorctl restart django:combo
