#!/usr/bin/env bash

LC_ALL=C

APP_NAME="x-theme"

SHARE="$HOME/.local/share"
BIN="$HOME/.local/bin"


while [ -n "$1" ]; do
    case "${1}" in
    --app)
        APP_NAME="${2}"
        ;;

    --prefix)
        SHARE="${2}/share"
        BIN="${2}/bin"
        ;;

    --path)
        SHARE="${2}/share"
        BIN="${2}"
        ;;
    esac
    shift
done

echo "app:   $APP_NAME"
echo "bin:   $BIN/$APP_NAME"
echo "share: $SHARE/$APP_NAME"
