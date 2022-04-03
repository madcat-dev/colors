#!/usr/bin/env bash
#
#	GTK-THEME
#		FlatColor
#

MODULE="$(dirname "$BASH_SOURCE")"

THEME_DIR="$HOME/.themes"
THEME="FlatColor"

if [[ ! "${1}" == "--force" ]]; then
	[[ -e "$THEME_DIR/$THEME" ]] \
		&& return 0
fi

debug "Install gtk theme '$THEME'"

if [[ ! -e "$MODULE/$THEME.tar.gz" ]]; then
	error "Theme '$THEME' archive not existing"
	return 1
fi

mkdir -p "$THEME_DIR"        2>/dev/null
rm   -rf "$THEME_DIR/$THEME" 2>/dev/null

tar -xzf "$MODULE/$THEME.tar.gz" -C "$THEME_DIR/"

