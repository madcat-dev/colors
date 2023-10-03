#!/usr/bin/env bash
#
#	XRDB
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors.Xresources" "${CACHE:-$HOME/.cache}/colors.Xresources" || return 1

xrdb -merge "${CACHE:-$HOME/.cache}/colors.Xresources"
