#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <nom-ou-package>"
    echo "Exemples:"
    echo "  $0 liege-taxes"
    echo "  $0 passerelle-imio-liege-taxes"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Accepte aussi bien "liege-taxes" que "passerelle-imio-liege-taxes"
INPUT="$1"
if [[ "$INPUT" == passerelle-imio-* ]]; then
    PACKAGE_NAME="$INPUT"
else
    SLUG=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
    PACKAGE_NAME="passerelle-imio-${SLUG}"
fi

MODULE_NAME=$(echo "$PACKAGE_NAME" | tr '-' '_')

DEST="${SCRIPT_DIR}/data/src/${PACKAGE_NAME}"

if [ ! -d "$DEST" ]; then
    echo "Erreur : le dossier ${DEST} n'existe pas."
    exit 1
fi

echo "Génération des migrations pour ${MODULE_NAME}..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/passerelle-manage makemigrations "${MODULE_NAME}"

echo "Application des migrations (migrate_schemas)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/passerelle-manage migrate_schemas --noinput

echo "Redémarrage de passerelle..."
docker exec publik-dev sudo supervisorctl restart django:passerelle

echo ""
echo "✅ Migrations appliquées pour ${PACKAGE_NAME}."
