.PHONY: setup-imio theme extra-cells fedict fields templatetags help

setup-imio: theme extra-cells fedict fields templatetags

theme:
	./install_theme.sh

extra-cells:
	./install_extra_cells.sh

fedict:
	./install_fedict.sh

fields:
	./install_imio_fields.sh

templatetags:
	./install_templatetags.sh

help:
	@echo "Cibles disponibles :"
	@echo "  setup-imio    - Installe un environement iMio"
	@echo "  theme         - Installe imio-publik-themes"
	@echo "  extra-cells   - Installe extra_cells pour combo"
	@echo "  fedict        - Installe authentic2-auth-fedict"
	@echo "  fields        - Configure les champs iMio"
	@echo "  templatetags  - Installe imio-teleservices-templatetags"
