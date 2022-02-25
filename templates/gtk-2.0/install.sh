#!/usr/bin/env bash
#
#	GTK-2.0
#
# Append 
#	export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc"
# to your ~/.profile file or replace ~/.gtkrc-2.0 file by gtkrc source

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/gtkrc" "$HOME/.config/gtk-2.0/gtkrc" || return 1

