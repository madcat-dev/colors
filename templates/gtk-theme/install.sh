#!/usr/bin/env bash
#
#	GTK-THEME
#

MODULE="$(dirname "$BASH_SOURCE")"

if [[ -d "$MODULE/$GTK_THEME_NAME" ]]; then
	source "$MODULE/$GTK_THEME_NAME/install.sh"
fi
