#
# Any wrappers from colors manager
# require: errors.lib.sh
# require: colors.lib.sh
#

# Lazy initialise
[[ ! ${CACHE} ]] && \
    CACHE="$HOME/.cache/colors" && \
    mkdir -p "$CACHE" > /dev/null 2>&1


# Extended color names list 
COLOR_KEYS=(
    0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    foreground
    background
    selection_foreground
    selection_background
    cursor
    url_color
    highlight
)


get() {
    local _rgb

    if [[ ${COLOR[${1}]} ]]; then
        _rgb=${COLOR[${1}]}
    else
        case "${1}" in
            foreground)
                _rgb=${COLOR[7]:-#FFFFFF}
                ;;
            background)
                _rgb=${COLOR[0]:-#000000}
                ;;
            cursor)
                _rgb=${COLOR[2]:-#FFFFFF}
                ;;
            highlight)
                _rgb=${COLOR[9]:-#FF0000}
                ;;
            url_color)
                _rgb=${COLOR[12]:-#0000FF}
                ;;
            selection_foreground)
                [[ ${GTK_APPLICATION_PREFER_DARK_THEME:-1} == 1 ]] && \
                    _rgb=${COLOR[0]:-#000000} || \
                    _rgb=${COLOR[7]:-#FFFFFF}
                ;;
            selection_background)
                [[ ${GTK_APPLICATION_PREFER_DARK_THEME:-1} == 1 ]] && \
                    _rgb=${COLOR[7]:-#FFFFFF} || \
                    _rgb=${COLOR[0]:-#000000}
                ;;
            0)
                _rgb=${COLOR[0]:-#0A0A0A}
                ;;
            8)
                _rgb=$(rgb_value ${COLOR[0]:-#0A0A0A} +15)
                ;;
            1|9)
                _rgb=${COLOR[1]:-#a54242}
                ;;
            2|10)
                _rgb=${COLOR[2]:-#8c9440}
                ;;
            3|11)
                _rgb=${COLOR[3]:-#de935f}
                ;;
            4|12)
                _rgb=${COLOR[4]:-#5f819d}
                ;;
            5|13)
                _rgb=${COLOR[5]:-#85678f}
                ;;
            6|14)
                _rgb=${COLOR[6]:-#5e8d87}
                ;;
            7)
                _rgb=${COLOR[7]:-#c8c8c8}
                ;;
            15)
                _rgb=$(rgb_value ${COLOR[7]:-#c8c8c8} +10)
                ;;
            *)
                ;;
        esac
    fi

    [[ ${_rgb} && $(isrgb "$_rgb") ]] && \
        echo "$_rgb" && return

    fatal "Color '${1}' invalid or not existing"
}


fill_special_colors() {
    [[ ${COLOR[foreground]} ]]           || COLOR[foreground]=$(get foreground)
    [[ ${COLOR[background]} ]]           || COLOR[background]=$(get background)
    [[ ${COLOR[cursor]} ]]               || COLOR[cursor]=$(get cursor)
    [[ ${COLOR[highlight]} ]]            || COLOR[highlight]=$(get highlight)
    [[ ${COLOR[url_color]} ]]            || COLOR[url_color]=$(get url_color)
    [[ ${COLOR[selection_foreground]} ]] || COLOR[selection_foreground]=$(get selection_foreground)
    [[ ${COLOR[selection_background]} ]] || COLOR[selection_background]=$(get selection_background)

    for i in {8..15}; do
        [[ ${COLOR[$i]} ]] || COLOR[$i]=$(get $i)
    done
}


ecolor() {
    printf "\033[48;2;%03d;%03d;%03dm" $(rgb ${1}) 
    echo -en "#\033[0m"
    printf "\033[38;2;%03d;%03d;%03dm" $(rgb ${1}) 
    echo -en "${1:1}\033[0m"
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

        echo -e "$(printf '─%.0s' {1..70})"

        printf '%-68s%s\n' \
            "background: $(ecolor $(get background))" \
            "selection_background: $(ecolor $(get selection_background))"

        printf '%-68s%s\n' \
            "foreground: $(ecolor $(get foreground))" \
            "selection_foreground: $(ecolor $(get selection_foreground))"

        printf '%-68s%-68s%-70s\n' \
            "cursor:     $(ecolor $(get cursor))" \
            "url_color: $(ecolor $(get url_color))" \
            "highlight: $(ecolor $(get highlight))"
    fi

    name=$(basename ${NAME:-UNKNOWN})
    preview "$name"
}


apply() {
    local SRCE="${1/\~/$HOME}"
    local DEST="${2/\~/$HOME}"


    [[ ! -f "$SRCE" ]] && \
        error "- Template '${SRCE/$HOME/\~}; not existing!" && return 1

    rm    -f "$DEST" > /dev/null 2>&1
    mkdir -p "$(dirname "$DEST")" > /dev/null 2>&1

    while read -r data; do
        data="${data//\"/\\x22}"
        data="${data//\*/\\x2A}"
        data="${data//\\/\\x5C}"

        echo -e "$( eval echo -e \"${data}\" )" >> $DEST 2>/dev/null || \
            return 1
    done < $SRCE
}
