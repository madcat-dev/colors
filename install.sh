#!/usr/bin/env bash

LC_ALL=C

APP_NAME="x-theme"

PREFIX="$HOME/.local"

while [ -n "$1" ]; do
    case "${1}" in
    --app)
        APP_NAME="${2}"
        ;;

    --prefix)
        PREFIX="$(realpath "${2}")"
        ;;
    esac
    shift
done

echo "app:   $APP_NAME"
echo "bin:   $PREFIX/bin/$APP_NAME"
echo "share: $PREFIX/share/$APP_NAME"
