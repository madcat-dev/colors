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
                _rgb=${COLOR[8]:-#FFFFFF}
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


install_xrdb_colors() {
    local DEST="$CACHE/xrdb"
    apply "$TEMPLATES/xrdb" "$DEST"
    xrdb -merge "$DEST" || return 1
}


install_terminals_colors() {
    local ERROR=() XFCE_SWITCH

    # kitty terminal
    apply "$TEMPLATES/kitty.conf" "$CACHE/kitty.colors.conf" || \
        ERROR+=( "- Kitty theme not applied" )

    # xfce-termanal
    apply "$TEMPLATES/xfce4-terminal.theme" "$CACHE/xfce4-terminal.theme" && \
        XFCE_SWITCH=true || ERROR+=( "- Xfce-terminal theme not applied" ) 

    if [[ ${XFCE_SWITCH} ]]; then
        $BASE/bin/xfce-color-switch "$CACHE/xfce4-terminal.theme" || \
            ERROR+=( "- Xfce-terminal theme not switched" )
    fi

    if [[ ${ERROR} ]]; then
        for i in ${!ERROR[@]}; do
            error "${ERROR[$i]}"
        done
        return 1
    fi
}


install_gtk2_colors() {
    local CFG="$HOME/.config"
    local TMPL="${TEMPLATES}/gtk-2.0"

    apply "$TMPL/colorsrc" "$CFG/gtk-2.0/colorsrc" || return 1
    apply "$TMPL/gtkrc"    "$CFG/gtk-2.0/gtkrc"    || return 1

    normal "    Append 'export GTK2_RC_FILES=\"\$HOME/.config/gtk-2.0/gtkrc\"'"
    normal "    to your .profile or replace ~/.gtkrc-2.0 by gtkrc source"
}

install_gtk3_colors() {
    local CFG="$HOME/.config"
    local TMPL="${TEMPLATES}/gtk-3.0"

    apply "$TEMPLATES/gtksourceview.xml" \
        "$HOME/.local/share/gtksourceview-3.0/styles/gtksourceview.xml" || \
        return 1

    apply "$TMPL/settings.ini" "$CFG/gtk-3.0/settings.ini" || return 1
    apply "$TMPL/colors.css"   "$CFG/gtk-3.0/colors.css"   || return 1
    apply "$TMPL/gtk.css"      "$CFG/gtk-3.0/gtk.css"      || return 1
}

install_gtk4_colors() {
    local CFG="$HOME/.config"
    local TMPL="${TEMPLATES}/gtk-4.0"

    apply "$TEMPLATES/gtksourceview.xml" \
        "$HOME/.local/share/gtksourceview-4/styles/gtksourceview.xml" || \
        return 1

    apply "$TMPL/settings.ini" "$CFG/gtk-4.0/settings.ini" || return 1
}


install_gtk_theme() {
    local GTK_THEME_NAME="${1}"

    [[ ! -e "$BASE/themes/${GTK_THEME_NAME:-Empty}.tar.gz" ]] && \
        error "Theme '${GTK_THEME_NAME}' not existing" && \
        return 1

    mkdir -p "$HOME/.themes" > /dev/null 2>&1
    tar -xzf "$BASE/themes/${GTK_THEME_NAME}.tar.gz" -C "$HOME/.themes" || \
        return 1
}


install_gtk_icon_theme() {
    local GTK_ICON_THEME_NAME="${1:-unknown}"
    local BRIGHT_VARIANT="${2}"
    local SRC_GTK_ICON_THEME_NAME=( ${GTK_ICON_THEME_NAME/\-\#/ } )

    [[ ! -e "$BASE/icons/${SRC_GTK_ICON_THEME_NAME:-Empty}.tar.gz" ]] && \
        error "- Icons theme '${GTK_ICON_THEME_NAME}' not existing" && \
        return 1

    local THEME_DIR="$HOME/.icons/${SRC_GTK_ICON_THEME_NAME}"

    mkdir -p "$HOME/.icons" > /dev/null 2>&1
    rm   -rf "$THEME_DIR"   > /dev/null 2>&1
    tar -xzf "$BASE/icons/${SRC_GTK_ICON_THEME_NAME}.tar.gz" -C "$HOME/.icons"

    [[ ! -e "$THEME_DIR" ]] && \
        error "- Icons theme '${SRC_GTK_ICON_THEME_NAME}' not prepeared" && \
        return 1

    if [[ "$SRC_GTK_ICON_THEME_NAME" != "$GTK_ICON_THEME_NAME" ]]; then
        local COLORS_VARIANT=( ${SRC_GTK_ICON_THEME_NAME[1]/-/ } )
        COLORS_VARIANT="#${COLORS_VARIANT[0]:-373A38}"

        if [[ -e "$THEME_DIR/colors.sh" ]]; then
            "$THEME_DIR/colors.sh" $COLORS_VARIANT  \
                $(rgb_value "$COLORS_VARIANT" +10%) \
                $(rgb_value "$COLORS_VARIANT" +20%) \
                "$BRIGHT_VARIANT" || return 1
        fi

        mv "$THEME_DIR" "$HOME/.icons/$GTK_ICON_THEME_NAME" || return 1
    fi
}


install_shell_colors() {
    local DEST="${1:-/unknown}"

    echo -e "# Shell colors" >  "$DEST" || return 1
    echo -e ""               >> "$DEST" || return 1

    for i in ${COLOR_KEYS[@]}; do
        if [[ $(isint $i) ]]; then
            echo -e "color$i='$(get $i)'"  >> "$DEST" || return 1
        else
            echo -e "color_$i='$(get $i)'" >> "$DEST" || return 1
        fi
    done
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
