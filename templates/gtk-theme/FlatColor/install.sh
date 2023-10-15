#!/usr/bin/env bash
#
#	GTK-THEME
#		FlatColor
#

MODULE="$(dirname "$BASH_SOURCE")"

THEME_DIR="$HOME/.themes"
THEME="FlatColor"

debug "Install gtk theme '$THEME'"

mkdir -p "$THEME_DIR"        2>/dev/null

#rm   -rf "$THEME_DIR/$THEME" 2>/dev/null

cp -xarf "$MODULE/$THEME" "$THEME_DIR/" || return 1

apply "$THEME_DIR/$THEME/gtk-2.0/gtkrc.base" \
    "$THEME_DIR/$THEME/gtk-2.0/gtkrc" || return 1

apply "$THEME_DIR/$THEME/gtk-3.0/gtk.css.base" \
    "$THEME_DIR/$THEME/gtk-3.0/gtk.css" || return 1

apply "$THEME_DIR/$THEME/gtk-3.20/gtk.css.base" \
    "$THEME_DIR/$THEME/gtk-3.20/gtk.css" || return 1
