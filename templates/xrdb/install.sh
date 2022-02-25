#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors.Xresources" "$HOME/.xrdb/colors.Xresources" || return 1

xrdb -merge "$HOME/.xrdb/colors.Xresources"
