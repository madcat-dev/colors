#!/usr/bin/env bash
#
#	GTK-4.0
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" || return 1

