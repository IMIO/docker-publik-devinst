.PHONY: setup-imio theme update-theme extra-cells update-extra-cells fedict fields templatetags help

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

help:
	@echo "Cibles disponibles :"
	@echo "  setup-imio    		- Installe un environement iMio"
	@echo "  theme         		- Installe imio-publik-themes"
	@echo "  update-theme  		- Met à jour imio-publik-themes"
	@echo "  extra-cells 			- Installe extra_cells pour combo"
	@echo "  update-extra-cells		- Met à jour extra_cells pour combo"
	@echo "  fedict        		- Installe authentic2-auth-fedict"
	@echo "  fields        		- Configure les champs iMio"
	@echo "  templatetags  		- Installe imio-teleservices-templatetags"
