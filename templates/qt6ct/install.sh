#!/usr/bin/env bash
#
#	QT6CT
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors.qss" "$HOME/.config/qt6ct/qss/colors.qss" || return 1

