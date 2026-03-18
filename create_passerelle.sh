#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <nom>"
    echo "Exemple: $0 'liege taxes'"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Conversions du nom
# slug  : minuscules, espaces/underscores -> tirets  (ex: liege-taxes)
# snake : minuscules, espaces/tirets -> underscores  (ex: liege_taxes)
SLUG=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
SNAKE=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' -' '_')

# Nom de la classe Python en CamelCase
CLASS_NAME=$(echo "$1" | sed 's/[-_ ]\([a-z]\)/\U\1/g;s/^./\u&/' | tr -d ' -_')

PACKAGE_NAME="passerelle-imio-${SLUG}"
MODULE_NAME="passerelle_imio_${SNAKE}"
DEST="${SCRIPT_DIR}/data/src/${PACKAGE_NAME}"

if [ -d "${DEST}" ]; then
    echo "Erreur : le dossier ${DEST} existe déjà."
    exit 1
fi

echo "Création de ${PACKAGE_NAME}..."

# Arborescence
mkdir -p "${DEST}/${MODULE_NAME}"

# README.md
cat > "${DEST}/README.md" <<EOF
# ${PACKAGE_NAME}

Connecteur iMio - ${1}
EOF

# setup.py
cat > "${DEST}/setup.py" <<EOF
from setuptools import setup, find_packages

version = "0.0.1"

setup(
    name="${PACKAGE_NAME}",
    version=version,
    author="iMio",
    author_email="support-ts@imio.be",
    packages=find_packages(),
    include_package_data=True,
    classifiers=[
        "Environment :: Web Environment",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.11",
    ],
    url="https://github.com/IMIO/${PACKAGE_NAME}",
    install_requires=[
        "django>=4.2",
    ],
    zip_safe=False,
)
EOF

# __init__.py
touch "${DEST}/${MODULE_NAME}/__init__.py"

# models.py
cat > "${DEST}/${MODULE_NAME}/models.py" <<EOF
import requests
from django.db import models
from passerelle.base.models import BaseResource
from passerelle.utils.api import endpoint
from passerelle.utils.jsonresponse import APIError
from requests import RequestException


class ${CLASS_NAME}(BaseResource):
    """
    Connecteur iMio - ${1}
    """

    url = models.URLField(
        max_length=255,
        blank=True,
        verbose_name="URL",
    )
    api_key = models.CharField(
        max_length=255,
        blank=True,
        verbose_name="Clé API",
    )
    api_description = "Connecteur iMio - ${1}"
    category = "Connecteurs iMio"

    class Meta:
        verbose_name = "Connecteur ${1}"

    @property
    def session(self):
        session = requests.Session()
        session.headers.update(
            {
                "X-Api-Key": self.api_key,
                "Accept": "application/json",
            }
        )
        return session
EOF

echo "✅ Connecteur créé dans ${DEST}"

# --- Installation en mode développement ---
echo "Installation en mode développement (pip install -e)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/pip install -e \
    "/home/publik/src/${PACKAGE_NAME}" --quiet

# --- Ajout dans les settings ---
SETTINGS_DIR="${SCRIPT_DIR}/data/config/publik/settings/passerelle/settings.d"
SETTINGS_FILE="${SETTINGS_DIR}/${MODULE_NAME}.py"
mkdir -p "$SETTINGS_DIR"
echo "Création de ${SETTINGS_FILE}..."
cat > "$SETTINGS_FILE" << EOF
INSTALLED_APPS += ('${MODULE_NAME}',)
TENANT_APPS += ('${MODULE_NAME}',)
EOF

# --- Génération des migrations ---
echo "Génération des migrations (makemigrations)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/passerelle-manage makemigrations "${MODULE_NAME}"

# --- Application des migrations ---
echo "Application des migrations (migrate_schemas)..."
docker exec publik-dev \
    /home/publik/envs/publik-env-py3/bin/passerelle-manage migrate_schemas --noinput

# --- Redémarrage ---
echo "Redémarrage de passerelle..."
docker exec publik-dev sudo supervisorctl restart django:passerelle

echo ""
echo "✅ ${PACKAGE_NAME} installé et actif."
echo "   Module  : ${MODULE_NAME}"
echo "   Source  : ${DEST}"
