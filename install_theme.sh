#!/bin/bash
set -e

# Chemins host (data/src est monté dans le container)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_SRC="${SCRIPT_DIR}/data/src"
THEME_SRC="${HOST_SRC}/imio-publik-themes"

# Chemins dans le container
CONTAINER_THEME_SRC="/home/publik/src/imio-publik-themes"
THEME_LINK="/usr/local/share/publik-devinst/themes/imio"

# Clone et submodules sur le host (SSH disponible)
test -d "${THEME_SRC}" || git clone gitea@git.entrouvert.org:entrouvert/imio-publik-themes.git "${THEME_SRC}"
cd "${THEME_SRC}"
git submodule update --init --recursive
cd -

# Symlink et make dans le container (environnement publik nécessaire)
docker exec publik-dev bash -c "test -e '${THEME_LINK}' || sudo ln -s '${CONTAINER_THEME_SRC}' '${THEME_LINK}'"
docker exec publik-dev bash -c "cd '${THEME_LINK}' && make"
