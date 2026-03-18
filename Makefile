.PHONY: setup-imio theme update-theme extra-cells update-extra-cells fedict fields templatetags create-passerelle install-passerelle help

setup-imio: theme extra-cells fedict fields templatetags

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
	./install_passerelle.sh "$(repo)"

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
	@echo "  install-passerelle repo=<url>		- Installe un connecteur existant depuis un repo git"
