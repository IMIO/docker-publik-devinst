#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <git-ssh-url>"
    echo "Exemple: $0 git@github.com:IMIO/passerelle-imio-liege-taxes.git"
    exit 1
fi

REPO_URL="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extrait le nom du package depuis l'URL (ex: passerelle-imio-liege-taxes)
PACKAGE_NAME=$(basename "$REPO_URL" .git)

# Vérifie que le nom commence par "passerelle-"
if [[ "$PACKAGE_NAME" != passerelle-* ]]; then
    echo "Erreur : le nom du repo '${PACKAGE_NAME}' ne commence pas par 'passerelle-'."
    exit 1
fi

# Dérive le nom du module Python (tirets -> underscores)
MODULE_NAME=$(echo "$PACKAGE_NAME" | tr '-' '_')

DEST="${SCRIPT_DIR}/data/src/${PACKAGE_NAME}"
SETTINGS_DIR="${SCRIPT_DIR}/data/config/publik/settings/passerelle/settings.d"
SETTINGS_FILE="${SETTINGS_DIR}/${MODULE_NAME}.py"

# --- 1. Clone ---
if [ -d "$DEST" ]; then
    echo "⚠️  Le dossier ${DEST} existe déjà, mise à jour (git pull)..."
    git -C "$DEST" pull
else
    echo "Clonage de ${REPO_URL}..."
    git clone "$REPO_URL" "$DEST"
fi

# --- 2. Installation en mode développement ---
echo "Installation en mode développement (pip install -e)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/pip install -e \
    "/home/publik/src/${PACKAGE_NAME}" --quiet

# --- 3. Ajout dans les settings ---
mkdir -p "$SETTINGS_DIR"
if [ -f "$SETTINGS_FILE" ]; then
    echo "⏩ Fichier settings ${SETTINGS_FILE} déjà présent, pas de modification."
else
    echo "Création de ${SETTINGS_FILE}..."
    cat > "$SETTINGS_FILE" << EOF
INSTALLED_APPS += ('${MODULE_NAME}',)
TENANT_APPS += ('${MODULE_NAME}',)
EOF
fi

# --- 4. Migration ---
echo "Application des migrations (migrate_schemas)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/passerelle-manage migrate_schemas --noinput

# --- 5. Redémarrage ---
echo "Redémarrage de passerelle..."
docker exec publik-dev sudo supervisorctl restart django:passerelle

echo ""
echo "✅ ${PACKAGE_NAME} installé et actif."
echo "   Module  : ${MODULE_NAME}"
echo "   Source  : ${DEST}"
