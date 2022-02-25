#!/usr/bin/env bash
#
#	QT5CT
#

MODULE="$(dirname "$BASH_SOURCE")"

apply "$MODULE/colors.qss" "$HOME/.config/qt5ct/qss/colors.qss" || return 1

