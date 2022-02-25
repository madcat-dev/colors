#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

URGENCY_LOW="#D6AF86"
URGENCY_NORMAL="#90A57E"
URGENCY_CRITICAL="#A26666"

apply "$MODULE/dunstrc" "$HOME/.config/dunst/dunstrc" || return 1

killall dunst 2>/dev/null
return 0
