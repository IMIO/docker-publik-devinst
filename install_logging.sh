#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="${SCRIPT_DIR}/data/config/publik/settings"

# Copie dans le settings.d de chaque brique
for app_dir in "${SETTINGS_DIR}"/*/; do
    mkdir -p "${app_dir}settings.d"
    cp "${SCRIPT_DIR}/logging_console.py" "${app_dir}settings.d/logging_console.py"
done

# Redémarrage des briques Django
docker exec publik-dev sudo supervisorctl restart 'django:*'
