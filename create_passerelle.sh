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
echo ""
echo "Prochaines étapes :"
echo "  1. Installer : docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python -m pip install -e /home/publik/src/${PACKAGE_NAME}"
echo "  2. Ajouter dans data/config/publik/settings/passerelle/settings.d/ :"
echo "       INSTALLED_APPS += ('${MODULE_NAME}',)"
echo "       TENANT_APPS += ('${MODULE_NAME}',)"
echo "  3. Migrations : docker exec publik-dev /home/publik/envs/publik-env-py3/bin/passerelle-manage makemigrations ${MODULE_NAME}"
echo "  4. Appliquer  : docker exec publik-dev /home/publik/envs/publik-env-py3/bin/passerelle-manage migrate_schemas"
echo "  5. Redémarrer : docker exec publik-dev sudo supervisorctl restart django:passerelle"
