
[[ ! ${CACHE} ]] && \
    CACHE="$HOME/.cache/colors"


normal() {
    echo -e "\033[37m${@}\033[0m" >&2
}

success() {
    echo -e "\033[32m${@}\033[0m" >&2
}

warning() {
    echo -e "\033[33m${@}\033[0m" >&2
}

error() {
    echo -e "\033[31m${@}\033[0m" >&2

    [[ ${ERROR_IS_FATAL} ]] && \
        kill $$
}

fatal() {
    echo -e "\033[31m${@}\033[0m" >&2
    kill $$ 
}


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


ecolor() {
    echo -en "\033[48:2:$(rgb_escapes "${1}")m#\033[0m"
    echo -en "\033[38:2:$(rgb_escapes "${1}")m${1:1}\033[0m"
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


apply() {
    SRCE="${1/\~/$HOME}"
    DEST="${2/\~/$HOME}"

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
    DEST="$CACHE/xrdb"
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
                $(saturation "$COLORS_VARIANT" +10) \
                $(saturation "$COLORS_VARIANT" +20) \
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
        if [[ $(int $i) ]]; then
            echo -e "color$i='${COLOR[$i]}'"  >> "$DEST" || return 1
        else
            echo -e "color_$i='${COLOR[$i]}'" >> "$DEST" || return 1
        fi
    done
}


store_configuration() {
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

    local f="${1:-/unknown}"

    echo "#!/usr/bin/env bash" > "$f" || return 1
    for i in ${KEYS[@]}; do
        value="${!i}"
        [[ ${value} ]] && echo "$i=\"$value\"" >> "$f" || return 1
    done

    echo "# colors" >> "$f" || return 1
    for i in ${!COLOR[@]}; do
        echo "COLOR[$i]=\"${COLOR[$i]}\"" >> "$f" || return 1
    done
}
