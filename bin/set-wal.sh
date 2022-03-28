#!/usr/bin/env bash

CFG="/etc/lightdm/lightdm-gtk-greeter.conf"
IMG="/usr/share/backgrounds/background.jpg"

if [[ ! -f "${1/\~/$HOME}" ]]; then
    echo -e "\033[31mImage not existing!\033[0m"
    exit 1
fi

if [[ $(id -u) -eq 0 ]]; then
    if ! convert "${1/\~/$HOME}" "$IMG"; then
        echo -e "\033[31mImage not converting!\033[0m"
        exit 1
    fi

    chmod 0644 "$IMG" || exit 1

    cp "$CFG" "$CFG.back" || exit 1

    cat "$CFG" | grep -vE '^background' > "$CFG.tmp" || exit 1
    echo "background = $IMG" >> "$CFG.tmp" || exit 1

    mv "$CFG.tmp" "$CFG" || exit 1

    exit 0
else
    echo -e "\033[31mChange privilegies!!!\033[0m"
    sudo $0 "${1}" || exit 1
fi

if [[ ! -f "$IMG" ]]; then
    echo -e "\033[31mNot background image existing!\033[0m"
    exit 1
fi

feh --bg-fill "$IMG"

echo -e "\033[32mSuccess!!!\033[0m"
