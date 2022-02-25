#!/usr/bin/env bash
#
#	GTK-ICON-THEME
#		Tela
#

MODULE="$(dirname "$BASH_SOURCE")"

ICONS="$HOME/.icons"
THEME="Tela"

debug "Install gtk icon theme '$THEME'"

if [[ ! -e "$MODULE/$THEME.tar.gz" ]]; then
	error "Icons theme '$THEME' archive not existing"
	return 1
fi

mkdir -p "$ICONS"        2>/dev/null
rm   -rf "$ICONS/$THEME" 2>/dev/null

tar -xzf "$MODULE/$THEME.tar.gz" -C "$ICONS/" || return 1

if [[ ! -e "$ICONS/$THEME" ]]; then
	return 1
fi


COLORS_VARIANT="${color2}"

if istrue ${GTK_APPLICATION_PREFER_DARK_THEME:-1}; then
	sed  -i "s/#565656/#aaaaaa/g" \
		"$ICONS/$THEME"/{16,22,24}/actions/*.svg || return 1

	sed  -i "s/#727272/#888888/g" \
		"$ICONS/$THEME"/{16,22,24}/{places,devices}/*.svg || return 1

	sed  -i "s/#555555/#aaaaaa/g" \
		"$ICONS/$THEME"/symbolic/{actions,apps,categories,devices}/*.svg || return 1

	sed  -i "s/#555555/#aaaaaa/g" \
		"$ICONS/$THEME"/symbolic/{emblems,emotes,mimetypes,places,status}/*.svg || return 1
fi

sed  -i "s/#5294E2/$COLORS_VARIANT/gi" \
	"$ICONS/$THEME"/scalable/places/default-*.svg || return 1

sed  -i "s/#66bcff/$(rgb_value "$COLORS_VARIANT" +10)/gi" \
	"$ICONS/$THEME"/scalable/places/default-*.svg || return 1

sed  -i "s/#b29aff/$(rgb_value "$COLORS_VARIANT" +20)/gi" \
	"$ICONS/$THEME"/scalable/places/default-*.svg || return 1

sed  -i "s/#5294E2/$COLORS_VARIANT/gi" \
	"$ICONS/$THEME"/16/places/folder*.svg || return 1
