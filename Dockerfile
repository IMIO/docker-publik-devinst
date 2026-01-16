FROM debian:bookworm

# 1. Installation des dépendances de base (Ajout de rabbitmq-server)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    git ansible make sudo \
    postgresql nginx supervisor rabbitmq-server \
    locales wget curl vim \
    build-essential python3-dev libpq-dev \
    acl gettext libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuration de la locale
RUN echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG=fr_FR.UTF-8
ENV LC_ALL=fr_FR.UTF-8

# 3. Création de l'utilisateur 'publik'
RUN useradd -m -s /bin/bash publik && \
    echo "publik ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Mock systemctl (pour éviter les erreurs Ansible)
RUN echo '#!/bin/bash\necho "Mock systemctl: $@"' > /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl

# 5. Préparation des répertoires
USER publik
WORKDIR /home/publik
RUN mkdir -p src envs .config/publik

# 6. Script de démarrage
COPY --chown=publik:publik entrypoint.sh /home/publik/entrypoint.sh
RUN chmod +x /home/publik/entrypoint.sh

CMD ["/home/publik/entrypoint.sh"]