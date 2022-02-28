#!/usr/bin/env bash

APP_NAME="x-theme"

BASE="$(dirname "${BASH_SOURCE:-$0}")"
PREFIX="$HOME/.local"

while [ -n "$1" ]; do
    case "${1}" in
    --prefix)
        PREFIX="$(realpath "${2}")"
        ;;
    esac
    shift
done

mkdir -p "$PREFIX/bin" 2>/dev/null

if ! cp -xar "$BASE/$APP_NAME" "$PREFIX/bin/"; then
    echo -e "\033[31m- Error of copy bin files\033[0m"
    exit 1
fi

if ! cp -xar "$BASE/bin" "$PREFIX"; then
    echo -e "\033[31m- Error of copy bin files\033[0m"
    exit 1
fi

mkdir -p "$PREFIX/lib" 2>/dev/null

if ! cp -xar "$BASE/lib" "$PREFIX"; then
    echo -e "\033[31m- Error of copy lib files\033[0m"
    exit 1
fi

mkdir -p "$PREFIX/share/$APP_NAME" 2>/dev/null

if ! cp -xar "$BASE/templates" "$PREFIX/share/$APP_NAME"; then
    echo -e "\033[31m- Error of copy templates files\033[0m"
    exit 1
fi

if ! cp -xar "$BASE/themes" "$PREFIX/share/$APP_NAME"; then
    echo -e "\033[31m- Error of copy themes files\033[0m"
    exit 1
fi

echo -e "\033[32mInstall successfully!\033[0m"
