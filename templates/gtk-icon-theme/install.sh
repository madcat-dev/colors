#!/usr/bin/env bash
#
#	GTK-ICON-THEME
#

MODULE="$(dirname "$BASH_SOURCE")"

if [[ -d "$MODULE/$GTK_ICON_THEME_NAME" ]]; then
	source "$MODULE/$GTK_ICON_THEME_NAME/install.sh"
fi
