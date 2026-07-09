.PHONY: setup-imio theme update-theme extra-cells update-extra-cells fedict fields templatetags create-passerelle install-passerelle migrate-passerelle restart-passerelle memcached renew-certificate industrialisation install-package change-branch help

setup-imio: theme extra-cells fedict fields templatetags memcached industrialisation

theme:
	./install_theme.sh

update-theme:
	cd data/src/imio-publik-themes && git pull
	docker exec publik-dev bash -c "cd /usr/local/share/publik-devinst/themes/imio && make"

extra-cells:
	./install_extra_cells.sh

update-extra-cells:
	cp extra_cells.py data/config/publik/settings/combo/settings.d/extra_cells.py
	docker exec publik-dev sudo supervisorctl restart django:combo

fedict:
	./install_fedict.sh

fields:
	./install_imio_fields.sh

templatetags:
	./install_templatetags.sh

create-passerelle:
	@test -n "$(name)" || (echo "Erreur : spécifier un nom, ex: make create-passerelle name='liege taxes'"; exit 1)
	./create_passerelle.sh "$(name)"

install-passerelle:
	@test -n "$(repo)" || (echo "Erreur : spécifier un repo, ex: make install-passerelle repo=git@github.com:IMIO/passerelle-imio-xxx.git"; exit 1)
	./install_passerelle.sh "$(repo)" "$(branch)"

migrate-passerelle:
	@test -n "$(name)" || (echo "Erreur : spécifier un nom, ex: make migrate-passerelle name=liege-taxes"; exit 1)
	./migrate_passerelle.sh "$(name)"

restart-passerelle:
	docker exec publik-dev sudo supervisorctl restart django:passerelle

memcached:
	docker exec publik-dev sudo service memcached start

renew-certificate:
	docker exec publik-dev sh -c 'cd /home/publik/src/publik-devinst && make renew-certificate ASKPASS=""'

industrialisation:
	./install_industrialisation.sh

install-package:
	@test -n "$(name)" || (echo "Erreur : spécifier un nom, ex: make install-package name=teleservices-package-light"; exit 1)
	./install_package.sh "$(name)" "$(branch)"

change-branch:
	@test -n "$(repo)" || (echo "Erreur : spécifier un repo, ex: make change-branch repo=passerelle-imio-liege-taxes branch=ma-branche"; exit 1)
	@test -n "$(branch)" || (echo "Erreur : spécifier une branche, ex: make change-branch repo=passerelle-imio-liege-taxes branch=ma-branche"; exit 1)
	@test -d "data/src/$(repo)" || (echo "Erreur : le dossier data/src/$(repo) n'existe pas"; exit 1)
	git -C "data/src/$(repo)" checkout "$(branch)"
	git -C "data/src/$(repo)" pull

help:
	@echo "Cibles disponibles :"
	@echo "  setup-imio				- Installe un environement iMio"
	@echo "  theme					- Installe imio-publik-themes"
	@echo "  update-theme				- Met à jour imio-publik-themes"
	@echo "  extra-cells				- Installe extra_cells pour combo"
	@echo "  update-extra-cells			- Met à jour extra_cells pour combo"
	@echo "  fedict				- Installe authentic2-auth-fedict"
	@echo "  fields				- Configure les champs iMio"
	@echo "  templatetags				- Installe imio-teleservices-templatetags"
	@echo "  create-passerelle name='mon nom'	- Crée un squelette de connecteur passerelle"
	@echo "  install-passerelle repo=<url> [branch=<branche>]	- Installe un connecteur existant depuis un repo git"
	@echo "  migrate-passerelle name=<nom>		- Génère et applique les migrations d'un connecteur"
	@echo "  restart-passerelle			- Redémarre passerelle"
	@echo "  memcached				- Démarre memcached dans le container"
	@echo "  renew-certificate			- Renouvelle le certificat TLS *.dev.publik.love"
	@echo "  industrialisation			- Installe publik-imio-industrialisation (commandes imio_indus_deploy, has_role, imio_import_directory)"
	@echo "  install-package name=<nom> [branch=<branche>]	- Installe un package (nom complet: pas de pull si existant, url ssh: pull si existant)"
	@echo "  change-branch repo=<nom> branch=<branche>	- Change la branche d'un repo dans data/src/"
