#!/bin/bash
set -e

# Mailpit intercepte les mails de toutes les briques (création de compte, notifications...).
# Le service est défini dans docker-compose.yml : interface http://localhost:10500, SMTP 10501 côté hôte,
# mailpit:1025 côté conteneur.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="${SCRIPT_DIR}/data/config/publik/settings"

# Démarre le service s'il ne tourne pas encore (sans toucher à publik-dev)
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" up -d mailpit

# Le settings.py de chaque brique fixe le backend « filebased » : on le remplace par le backend SMTP
for brique in authentic2-multitenant hobo combo passerelle chrono lingo wcs; do
    mkdir -p "${SETTINGS}/${brique}/settings.d"
    cat > "${SETTINGS}/${brique}/settings.d/mailpit.py" <<'PY'
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'mailpit'
EMAIL_PORT = 1025
EMAIL_USE_TLS = False
EMAIL_HOST_USER = ''
EMAIL_HOST_PASSWORD = ''
PY
done

# Redémarrage des briques (groupe django:* uniquement : "restart all" démarre aussi uwsgi:* et provoque des conflits de ports)
docker exec publik-dev sudo supervisorctl restart 'django:*'
