#!/usr/bin/env bash
#
#	XFCE4-TERMINAL
#

MODULE="$(dirname "$BASH_SOURCE")"

PATHS=(
    "$HOME/.local/share/xfce4/terminal/colorschemes"
    "/usr/local/share/xfce4/terminal/colorschemes"
    "/usr/share/xfce4/terminal/colorschemes"
)

TMP="$CACHE/terminalrc.tmp"
BAK="$CACHE/terminalrc.bak"

apply_theme() {
    mkdir -p ~/.config/xfce4/terminal > /dev/null 2>&1
    cd ~/.config/xfce4/terminal

    cat terminalrc | grep -v Color | grep -v FontName > $TMP
    grep -e Color    "$1" >> $TMP
    grep -e FontName "$1" >> $TMP

	cp terminalrc $BAK
	mv $TMP terminalrc
}

if apply "$MODULE/xfce4-terminal.theme" "$CACHE/xfce4-terminal.theme"; then
	apply_theme "$CACHE/xfce4-terminal.theme" || return 1
	return 0
fi

return 1
