#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_SRC="${SCRIPT_DIR}/data/src"
FEDICT_SRC="${HOST_SRC}/authentic2-auth-fedict"
CONTAINER_FEDICT_SRC="/home/publik/src/authentic2-auth-fedict"
SETTINGS_D="${SCRIPT_DIR}/data/config/publik/settings/authentic2-multitenant/settings.d"

# Clone sur le host (SSH disponible)
test -d "${FEDICT_SRC}" || git clone gitea@git.entrouvert.org:entrouvert/authentic2-auth-fedict.git "${FEDICT_SRC}"

# Installation en mode éditable dans le container
docker exec publik-dev /home/publik/envs/publik-env-py3/bin/python -m pip install -e "${CONTAINER_FEDICT_SRC}"

# Création du fichier de settings
mkdir -p "${SETTINGS_D}"
cat > "${SETTINGS_D}/fedict.py" <<'EOF'
if 'authentic2_auth_fedict' not in INSTALLED_APPS:
    INSTALLED_APPS += ('authentic2_auth_fedict',)
if 'authentic2_auth_fedict' not in TENANT_APPS:
    TENANT_APPS += ('authentic2_auth_fedict',)
if 'authentic2_auth_fedict.backends.FedictBackend' not in AUTHENTICATION_BACKENDS:
    AUTHENTICATION_BACKENDS += ('authentic2_auth_fedict.backends.FedictBackend',)

A2_AUTH_FEDICT_ENABLE = True

MELLON_ADAPTER = ('authentic2_auth_fedict.adapters.AuthenticAdapter',)
MELLON_LOGIN_URL = "fedict-login"
MELLON_PUBLIC_KEYS = ["/var/lib/authentic2-multitenant/tenants/authentic.dev.publik.love/saml.crt"]
MELLON_PRIVATE_KEY = "/var/lib/authentic2-multitenant/tenants/authentic.dev.publik.love/saml.key"
EOF

# Redémarrage d'authentic
docker exec publik-dev sudo supervisorctl restart django:authentic2-multitenant

# Migration
docker exec publik-dev /home/publik/envs/publik-env-py3/bin/authentic2-multitenant-manage migrate_schemas
