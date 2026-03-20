#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-ou-url>"
    echo "Exemples:"
    echo "  $0 teleservices-package-light"
    echo "  $0 git@github.com:IMIO/teleservices-package-light.git"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Résolution du repo : nom complet ou URL SSH
INPUT="$1"
if [[ "$INPUT" == git@* || "$INPUT" == https://* ]]; then
    REPO_URL="$INPUT"
    PACKAGE_NAME=$(basename "$REPO_URL" .git)
else
    PACKAGE_NAME="$INPUT"
    REPO_URL="git@github.com:IMIO/${PACKAGE_NAME}.git"
fi

DEST="${SCRIPT_DIR}/data/src/${PACKAGE_NAME}"

# Dérive le sous-dossier Python du package (tirets -> underscores)
MODULE_NAME=$(echo "$PACKAGE_NAME" | tr '-' '_')

# --- 1. Clone ou mise à jour ---
if [ -d "$DEST" ]; then
    echo "⚠️  Le dossier ${DEST} existe déjà, mise à jour (git pull)..."
    git -C "$DEST" pull
else
    echo "Clonage de ${REPO_URL}..."
    git clone "$REPO_URL" "$DEST"
fi

CONTENT_DIR="${DEST}/${MODULE_NAME}"
if [ ! -d "$CONTENT_DIR" ]; then
    echo "Erreur : le dossier de contenu ${CONTENT_DIR} n'existe pas."
    exit 1
fi

# --- 2. Patch des JSON combo (champs manquants pour la version actuelle de combo) ---
if [ -d "${CONTENT_DIR}/combo" ]; then
    echo "Patch des fichiers combo JSON (last_update_timestamp, uuid)..."
    python3 - "${CONTENT_DIR}/combo" << 'EOF'
import json, uuid, sys, os
from datetime import datetime, timezone

ts = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f+00:00')
combo_dir = sys.argv[1]

for fname in os.listdir(combo_dir):
    if not fname.endswith('.json'):
        continue
    path = os.path.join(combo_dir, fname)
    d = json.load(open(path))
    pages_count = cells_count = links_count = 0
    for page in d.get('pages', []):
        if 'last_update_timestamp' not in page.get('fields', {}):
            page['fields']['last_update_timestamp'] = ts
            pages_count += 1
        for cell in page.get('cells', []):
            if 'last_update_timestamp' not in cell.get('fields', {}):
                cell['fields']['last_update_timestamp'] = ts
                cells_count += 1
            for link in cell.get('links', []):
                if 'last_update_timestamp' not in link.get('fields', {}):
                    link['fields']['last_update_timestamp'] = ts
                    links_count += 1
                if 'uuid' not in link.get('fields', {}):
                    link['fields']['uuid'] = str(uuid.uuid4())
    with open(path, 'w') as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
    print(f"  {fname}: {pages_count} pages, {cells_count} cells, {links_count} links patchés")
EOF
fi

# --- 3. Import via imio_indus_deploy ---
echo "Import du contenu via imio_indus_deploy..."
HOBO_TENANT=$(docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/hobo-manage list_tenants 2>/dev/null \
    | grep -v RequestsDependency | grep -v warnings.warn | grep -v urllib3 \
    | awk '{print $2}' | head -1)

docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/hobo-manage imio_indus_deploy \
    -d "$HOBO_TENANT" \
    --directory "/home/publik/src/${PACKAGE_NAME}/${MODULE_NAME}" \
    2>&1 | grep -v RequestsDependencyWarning | grep -v warnings.warn | grep -v urllib3

echo ""
echo "✅ ${PACKAGE_NAME} installé."
