#!/bin/bash
set -e

# --- 1. CONFIGURATION SYSTÈME (A FAIRE À CHAQUE DÉMARRAGE) ---
# Ces services s'arrêtent quand le docker s'arrête, il faut donc 
# impérativement les relancer à chaque "docker start".

echo "Configuring loopback aliases..."
if ! grep -q "authentic.dev.publik.love" /etc/hosts; then
    echo "127.0.0.1 agent-combo.dev.publik.love authentic.dev.publik.love bijoe.dev.publik.love chrono.dev.publik.love combo.dev.publik.love fargo.dev.publik.love hobo.dev.publik.love passerelle.dev.publik.love wcs.dev.publik.love lingo.dev.publik.love" | sudo tee -a /etc/hosts > /dev/null
fi

echo "Fixing permissions..."
sudo chown -R publik:publik /home/publik/.config /home/publik/envs /home/publik/src

echo "Starting System Services..."
sudo service postgresql start
sudo service nginx start
sudo service rabbitmq-server start

echo "Waiting for RabbitMQ..."
while ! sudo rabbitmqctl status > /dev/null 2>&1; do sleep 2; done

# --- 2. INSTALLATION (UNIQUEMENT SI PAS ENCORE FAIT) ---
DIR_SRC="/home/publik/src/publik-devinst"
FILE_TO_PATCH="$DIR_SRC/roles/base/tasks/main.yml"
MARKER_FILE="/home/publik/.installed" # <--- Le fichier témoin

if [ ! -f "$MARKER_FILE" ]; then
    echo "⚡ Installation initiale détectée (ou marqueur absent)."

    if [ ! -d "$DIR_SRC" ]; then
        echo "Clonage de publik-devinst..."
        mkdir -p /home/publik/src && cd /home/publik/src
        git clone https://git.entrouvert.org/publik-devinst.git
    fi

    # Patch systemd
    if [ -f "$FILE_TO_PATCH" ] && grep -q "systemd daemon-reload" "$FILE_TO_PATCH"; then
        echo "Applying systemd patch..."
        sed -i '/- name: systemd daemon-reload/,/when: supervisor_override.changed or supervisor_d.changed/d' "$FILE_TO_PATCH"
    fi

    cd "$DIR_SRC"
    echo "Running make install..."
    PYTHONUNBUFFERED=1 make install ASKPASS=""
    
    # On crée le fichier témoin pour ne plus repasser ici
    touch "$MARKER_FILE"
    echo "✅ Installation terminée et marquée."
else
    echo "⏩ Installation déjà effectuée (fichier .installed trouvé). On passe."
fi

# --- 3. DÉMARRAGE DES APPLICATIFS ---
echo "Starting Supervisord..."
sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Attente que les sockets soient prêts
sleep 5

# --- 4. DÉPLOIEMENT ---
if [ ! -f "/home/publik/.deployed" ]; then
    echo "Deploying tenants..."
    cd "$DIR_SRC"
    make deploy ASKPASS="" && touch /home/publik/.deployed
else
    echo "⏩ Tenants déjà déployés."
fi

# --- 5. LOGS ---
echo "Services are up. Tailing supervisor logs..."
sudo tail -f /var/log/supervisor/supervisord.log