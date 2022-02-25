#!/usr/bin/env bash
#
#	GTK-3.0
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/settings.ini" "$HOME/.config/gtk-3.0/settings.ini" || return 1
apply "$MODULE/gtk.css"      "$HOME/.config/gtk-3.0/gtk.css"      || return 1

