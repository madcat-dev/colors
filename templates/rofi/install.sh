#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors-rofi.rasi" "$HOME/.config/rofi/colors-rofi.rasi" || return 1

