#!/bin/bash
set -e

REPO_URL="gitea@git.entrouvert.org:entrouvert/publik-imio-industrialisation.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${SCRIPT_DIR}/data/src/publik-imio-industrialisation"

# --- 1. Clone ou mise à jour ---
if [ -d "$DEST" ]; then
    echo "⚠️  Le dossier ${DEST} existe déjà, mise à jour (git pull)..."
    git -C "$DEST" pull
else
    echo "Clonage de ${REPO_URL}..."
    git clone "$REPO_URL" "$DEST"
fi

# --- 2. Copie des management commands dans les apps ---
echo "Copie des management commands..."

HOBO_CMD_DIR=$(docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python \
    -c "import hobo.environment; import os; print(os.path.join(os.path.dirname(hobo.environment.__file__), 'management', 'commands'))")
COMBO_CMD_DIR=$(docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python \
    -c "import combo.data; import os; print(os.path.join(os.path.dirname(combo.data.__file__), 'management', 'commands'))")
WCS_CMD_DIR=$(docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python \
    -c "import wcs.ctl; import os; print(os.path.join(os.path.dirname(wcs.ctl.__file__), 'management', 'commands'))")

docker exec publik-dev cp /home/publik/src/publik-imio-industrialisation/hobo/imio_indus_deploy.py "${HOBO_CMD_DIR}/"
docker exec publik-dev cp /home/publik/src/publik-imio-industrialisation/combo/has_role.py "${COMBO_CMD_DIR}/"
docker exec publik-dev cp /home/publik/src/publik-imio-industrialisation/wcs/imio_import_directory.py "${WCS_CMD_DIR}/"
docker exec publik-dev cp /home/publik/src/publik-imio-industrialisation/wcs/has_role.py "${WCS_CMD_DIR}/"

echo "hobo: OK | combo: OK | wcs: OK"

# --- 3. Patch de l'import cassé dans imio_indus_deploy.py ---
# hobo.agent.worker n'existe plus, les settings MANAGE_COMMAND sont dans django.conf.settings
DEPLOY_CMD="${HOBO_CMD_DIR}/imio_indus_deploy.py"
docker exec publik-dev sed -i \
    's/from hobo\.agent\.worker import settings as agent_settings/from django.conf import settings as agent_settings/' \
    "$DEPLOY_CMD"
echo "Patch imio_indus_deploy.py: OK"

# --- 4. Vérification ---
echo ""
echo "Vérification des commandes disponibles..."
docker exec publik-dev bash -c "
    /home/publik/envs/publik-env-py3/bin/hobo-manage help imio_indus_deploy 2>&1 | grep 'usage:' &&
    /home/publik/envs/publik-env-py3/bin/combo-manage help has_role 2>&1 | grep 'usage:' &&
    /home/publik/envs/publik-env-py3/bin/wcs-manage help imio_import_directory 2>&1 | grep 'usage:' &&
    /home/publik/envs/publik-env-py3/bin/wcs-manage help has_role 2>&1 | grep 'usage:'
" 2>&1 | grep -v RequestsDependencyWarning | grep -v warnings.warn | grep -v urllib3

echo ""
echo "✅ publik-imio-industrialisation installé."
echo "   Commandes disponibles :"
echo "   - hobo-manage imio_indus_deploy"
echo "   - combo-manage has_role"
echo "   - wcs-manage imio_import_directory"
echo "   - wcs-manage has_role"
