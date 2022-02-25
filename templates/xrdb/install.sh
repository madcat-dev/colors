#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors.Xresources" "$HOME/.config/xrdb/colors.Xresources" || return 1

xrdb -merge "$HOME/.config/xrdb/colors.Xresources"
