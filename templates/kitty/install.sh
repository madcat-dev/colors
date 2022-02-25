#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors-kitty.conf" "$HOME/.config/kitty/colors-kitty.conf" || return 1

