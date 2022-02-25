#!/usr/bin/env bash
#
#	GTKSOURCEVIEW
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/gtksourceview.xml" \
	"$HOME/.local/share/gtksourceview-3.0/styles/gtksourceview.xml" \
	|| return 1

apply "$MODULE/gtksourceview.xml" \
	"$HOME/.local/share/gtksourceview-4/styles/gtksourceview.xml" \
	|| return 1
