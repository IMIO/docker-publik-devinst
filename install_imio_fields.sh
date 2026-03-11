#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTHENTIC_SETTINGS_D="${SCRIPT_DIR}/data/config/publik/settings/authentic2-multitenant/settings.d"
HOBO_SETTINGS="${SCRIPT_DIR}/data/config/publik/settings/hobo"

# Création du fichier kind.py dans les settings d'authentic
mkdir -p "${AUTHENTIC_SETTINGS_D}"
cat > "${AUTHENTIC_SETTINGS_D}/kind.py" <<'EOF'
# -*- coding: utf-8 -*-

from django import forms
import re


class RrnField(forms.CharField):
    def validate(self, value):
        super(RrnField, self).validate(value)
        if not value:
            return
        try:
            if (97 - int(value[:9]) % 97) != int(value[-2:]):
                raise ValueError()
        except ValueError:
            raise forms.ValidationError("Format invalide")


class NumHouseField(forms.CharField):
    def validate(self, value):
        super(NumHouseField, self).validate(value)
        if not value:
            return
        try:
            if not re.match("[1-9][0-9]*", value):
                raise ValueError()
        except ValueError:
            raise forms.ValidationError("Format invalide")


class NumPhoneField(forms.CharField):
    def validate(self, value):
        super(NumPhoneField, self).validate(value)
        if not value:
            return
        try:
            if not re.match("^(0|\\+|00)(\d{8,})", value):
                raise ValueError()
        except ValueError:
            raise forms.ValidationError("Format invalide")


A2_ATTRIBUTE_KINDS = [
    {
        'label': u'Numéro de registre national',
        'name': 'rrn',
        'field_class': RrnField,
    },
    {
        'label': u'Numéro de maison',
        'name': 'num_house',
        'field_class': NumHouseField,
    },
    {
        'label': u'Numéro de téléphone',
        'name': 'phone',
        'field_class': NumPhoneField,
    }
]
EOF

# Création du recipe.json dans les settings de hobo
mkdir -p "${HOBO_SETTINGS}"
cat > "${HOBO_SETTINGS}/recipe.json" <<'EOF'
{
  "steps": [
    {
      "create-hobo": {
        "url": "https://hobo.dev.publik.love/"
      }
    },
    {
      "set-attribute": {
        "name": "niss",
        "label": "Numéro national",
        "description": "Le n° d'identification au Registre national se trouve sur la carte d'identité.",
        "kind": "nrn",
        "enabled": true
      }
    }
  ]
}
EOF

# Redémarrage d'authentic pour prendre en compte kind.py
docker exec publik-dev sudo supervisorctl restart django:authentic2-multitenant

# Lancement du cook hobo
docker exec publik-dev /home/publik/envs/publik-env-py3/bin/hobo-manage cook /home/publik/.config/publik/settings/hobo/recipe.json
