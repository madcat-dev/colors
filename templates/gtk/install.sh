#!/usr/bin/env bash
#
#	GTK-2.0
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/gtkrc"        "$HOME/.config/gtk-2.0/gtkrc" || return 1

apply "$MODULE/settings.ini" "$HOME/.config/gtk-3.0/settings.ini" || return 1
apply "$MODULE/gtk.css"      "$HOME/.config/gtk-3.0/gtk.css"      || return 1

apply "$MODULE/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" || return 1

info 'Append:' 
info '\texport GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc"'
info 'to your ~/.profile file or replace ~/.gtkrc-2.0 file by gtkrc source'

