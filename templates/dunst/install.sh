#!/usr/bin/env bash
#
#	DUNST
#

MODULE="$(dirname "$BASH_SOURCE")"

URGENCY_LOW="#D6AF86"
URGENCY_NORMAL="#90A57E"
URGENCY_CRITICAL="#A26666"

if apply "$MODULE/dunstrc" "$HOME/.config/dunst/dunstrc"; then
	killall dunst 2>/dev/null
	return 0
fi

return 1
