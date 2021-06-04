

function displaytime {
    local T=$1
    local W=$((T/60/60/24/7))
    local D=$((T/60/60/24%7))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))

    if [[ $W > 0 ]]; then
        printf '%d weeks ' $W
        printf '%d days ' $D
    else
        if [[ $D > 0 ]]; then
            printf '%d days ' $D
            printf '%d hours ' $H
        else
            [[ $H > 0 ]] && printf '%d hours ' $H
            [[ $M > 0 ]] && printf '%d minutes ' $M
            [[ $H = 0 ]] && printf '%d seconds ' $S
        fi
    fi

    printf 'ago'
}


preview_theme() {
    if [[ ! ${SHORT_PREVIEW} ]]; then
        [[ ${COLOR[name]} ]] && \
            printf "%-15s%s\n"      "Name:"         "${COLOR[name]}"

        [[ ${NAME} ]] && \
            printf "%-15s%s\n"      "Path:"         "${NAME/$HOME/\~}"

        [[ ${COLOR[description]} ]] && \
            printf "%-15s%s...\n"   "Description:"  "${COLOR[description]:0:54}"

        [[ ${COLOR[image]} ]] && \
            printf "%-15s%s\n"      "Image:"        "${COLOR[image]}"

        [[ ${GTK_THEME_NAME} ]] && \
            printf "%-15s%s\n"      "Gtk theme:"    "${GTK_THEME_NAME}"

        [[ ${GTK_ICON_THEME_NAME} ]] && \
            printf "%-15s%s\n"      "Icons theme:"  "${GTK_ICON_THEME_NAME}"

        [[ ${GTK_FONT_NAME} ]] && \
            printf "%-15s%s\n"      "Font name:"    "${GTK_FONT_NAME}"

        echo -e "$(printf '─%.0s' {1..72})"

        printf '%-68s%s\n' \
            "background: $(ecolor ${COLOR[background]:-${COLOR[0]}})" \
            "selection_background: $(ecolor ${COLOR[selection_background]:-${COLOR[7]}})"
        printf '%-68s%s\n' \
            "foreground: $(ecolor ${COLOR[foreground]:-${COLOR[15]}})" \
            "selection_foreground: $(ecolor ${COLOR[selection_foreground]:-${COLOR[0]}})"
        printf '%-68s%-68s%-70s\n' \
            "cursor:     $(ecolor ${COLOR[cursor]:-${COLOR[8]}})" \
            "url_color: $(ecolor ${COLOR[url_color]:-${COLOR[12]}})" \
            "highlight: $(ecolor ${COLOR[highlight]:-${COLOR[9]}})"

        echo -e "$(printf '─%.0s' {1..72})"

        echo -e "   BLK      RED      GRN      YEL      BLU      MAG      CYN      WHT"
        echo -e "$(printf '─%.0s' {1..72})"
    else
        name=$(basename ${NAME:-UNKNOWN})
        len=$(echo "72 - ${#name} - 4" | bc -s)

        echo -en `printf '─%.0s' $(seq $len)`
        echo -e "[ ${name} ]"
    fi


    echo -en "\033[48:2:$(rgb_escapes "${COLOR[background]:-${COLOR[0]}}")m"
    for i in {0..7}; do
        [[ "${COLOR[$i]}" == "${COLOR[background]:-${COLOR[0]}}" ]] && \
            echo -en "\033[38:2:$(rgb_escapes "#FFFFFF")m${COLOR[$i]}  " || \
            echo -en "\033[38:2:$(rgb_escapes "${COLOR[$i]}")m${COLOR[$i]}  "
    done
    echo -e "\033[0m"

    echo -en "\033[48:2:$(rgb_escapes "${COLOR[background]:-${COLOR[0]}}")m"
    for i in {8..15}; do
        [[ "${COLOR[$i]}" == "${COLOR[background]:-${COLOR[0]}}" ]] && \
            echo -en "\033[38:2:$(rgb_escapes "#FFFFFF")m${COLOR[$i]}  " || \
            echo -en "\033[38:2:$(rgb_escapes "${COLOR[$i]}")m${COLOR[$i]}  "
    done
    echo -e "\033[0m"

    [[ ! ${SHORT_PREVIEW} ]] && echo -e "$(printf '─%.0s' {1..72})"
}


install_theme() {
    SRCE="${1}"
    DEST="${2}"

    [[ ! -f "$SRCE" ]] && \
        echo -e "\033[32m[-] Template $SRCE not existing!\033[0m" && \
        return

    rm -f $DEST > /dev/null 2>&1
    mkdir -p "$(dirname $DEST)" > /dev/null 2>&1

    while IFS=\# read -r data end; do
        data=$(eval echo -e \"${data//\"/\\\"}\")
        end=$(eval echo -e \"${end//\"/\\\"}\")


        [[ "$end" ]] && end="#$end"
        [[ "$data$end" ]] && echo -e "$data$end" >> $DEST
    done < $SRCE
}


