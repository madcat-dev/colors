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
                _rgb=${COLOR[15]:-#FFFFFF}
                ;;
            background)
                _rgb=${COLOR[0]:-#000000}
                ;;
            cursor)
                _rgb=$(rgb_value ${COLOR[2]:-#FFFFFF} +5%)
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

    rm -f "$DEST" > /dev/null 2>&1
    mkdir -p "$(dirname "$DEST")" > /dev/null 2>&1

    while IFS=\# read -r data end; do
        data=$( eval echo -e \"${data//\"/\\\"}\" )
        end=$(  eval echo -e \"${end//\"/\\\"}\"  )

        [[ "$end" ]] && end="#$end"

        if [[ "$data$end" ]]; then
            echo -e "$data$end" >> $DEST 2>/dev/null || return 1
        fi
    done < $SRCE
}


store_configuration() {
    local f="${1:-/unknown}"
    local KEYS=(
        GTK_THEME_NAME 
        GTK_ICON_THEME_NAME
        GTK_FONT_NAME
        GTK_CURSOR_THEME_SIZE
        GTK_TOOLBAR_STYLE
        GTK_TOOLBAR_ICON_SIZE
        GTK_BUTTON_IMAGES
        GTK_MENU_IMAGES
        GTK_DECORATION_LAYOUT    
        GTK_ENABLE_EVENT_SOUNDS
        GTK_ENABLE_INPUT_FEEDBACK_SOUNDS
        GTK_XFT_ANTIALIAS
        GTK_XFT_HINTING
        GTK_XFT_HINTSTYLE
        GTK_XFT_RGBA
    )

    mkdir -p "$(dirname "$f")" > /dev/null 2>&1

    echo "#!/usr/bin/env bash" > "$f" || return 1
    for i in ${KEYS[@]}; do
        value="${!i}"
        if [[ ${value} ]]; then
            echo "$i=\"$value\"" >> "$f" || return 1
        fi
    done

    echo "# colors" >> "$f" || return 1
    for i in ${!COLOR[@]}; do
        echo "COLOR[$i]=\"$(get $i)\"" >> "$f" || return 1
    done
}
