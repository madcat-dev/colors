#!/usr/bin/env bash
#
#	Kvantum XTheme
#

MODULE="$(dirname "$BASH_SOURCE")"
KVANTUM="$HOME/.config/Kvantum/XTheme"

mkdir -p "$KVANTUM" > /dev/null 2>&1
cp "$MODULE/XTheme.svg" "$KVANTUM" || return 1

# background
sed  -i "s/#1b2224/${background}/gi" \
	"$KVANTUM/XTheme.svg" || return 1

# base color / black
sed  -i "s/#222b2e/${color0}/gi" \
	"$KVANTUM/XTheme.svg" || return 1

# button color 
sed  -i "s/#263034/$(rgb_value ${color0} +2)/gi" \
	"$KVANTUM/XTheme.svg" || return 1

# button color 2
sed  -i "s/#39494f/$(rgb_value ${color0} +12)/gi" \
	"$KVANTUM/XTheme.svg" || return 1

# selected color / green
sed  -i "s/#2eb398/${color2}/gi" \
	"$KVANTUM/XTheme.svg" || return 1

# selected color / green
if isfalse ${GTK_APPLICATION_PREFER_DARK_THEME:-1}; then
    sed  -i "s/#dfdfdf/$(rgb_value '#dfdfdf' -50)/gi" \
        "$KVANTUM/XTheme.svg" || return 1

    sed  -i "s/#f5f5f5/$(rgb_value '#f5f5f5' -20)/gi" \
        "$KVANTUM/XTheme.svg" || return 1
fi

apply "$MODULE/XTheme.kvconfig" "$KVANTUM/XTheme.kvconfig" || return 1
