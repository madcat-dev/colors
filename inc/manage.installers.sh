
install_xrdb_colors() {
    local DEST="$CACHE/xrdb"
    apply "$TEMPLATES/xrdb" "$DEST"
    xrdb -merge "$DEST" || return 1
}


install_terminals_colors() {
    local ERROR=() XFCE_SWITCH=

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


install_FlatColor_gtk_theme() {
    # Based on https://github.com/deviantfero/wpgtk-templates/tree/master/FlatColor
    [[ ! -e "$TEMPLATES/FlatColor.tar.gz" ]] && \
        error "Theme 'FlatColor' not existing" && \
        return 1

    mkdir -p "$HOME/.themes" > /dev/null 2>&1
    tar -xzf "$TEMPLATES/FlatColor.tar.gz" -C "$HOME/.themes" || \
        return 1
}


install_Tela_icon_theme() {
    # Based on https://github.com/vinceliuice/Tela-icon-theme
    local BRIGHT_VARIANT="${1}"
    local THEME="$HOME/.icons/Tela"

    [[ ${BRIGHT_VARIANT} ]] &&
        BRIGHT_VARIANT="-dark"

    [[ ! -e "$TEMPLATES/Tela.tar.gz" ]] && \
        error "- Icons theme 'Tela' not existing" && \
        return 1

    mkdir -p "$(dirname "$THEME")" > /dev/null 2>&1
    rm   -rf "$THEME" > /dev/null 2>&1
    tar -xzf "$TEMPLATES/Tela.tar.gz" -C "$HOME/.icons/"

    [[ ! -e "$THEME" ]] && \
        error "- Icons theme 'Tela' not prepeared" && \
        return 1

    local COLORS_VARIANT="$(get 2)"

    if [[ ${BRIGHT_VARIANT} ]]; then
        sed  -i "s/#565656/#aaaaaa/g" \
            "$THEME"/{16,22,24}/actions/*.svg || return 1

        sed  -i "s/#727272/#aaaaaa/g" \
            "$THEME"/{16,22,24}/{places,devices}/*.svg || return 1

        sed  -i "s/#555555/#aaaaaa/g" \
            "$THEME"/symbolic/{actions,apps,categories,devices}/*.svg || return 1

        sed  -i "s/#555555/#aaaaaa/g" \
            "$THEME"/symbolic/{emblems,emotes,mimetypes,places,status}/*.svg || return 1
    fi

    sed  -i "s/#5294E2/$COLORS_VARIANT/gi" \
        "$THEME"/scalable/places/default-*.svg || return 1

    sed  -i "s/#66bcff/$(rgb_value "$COLORS_VARIANT" +10)/gi" \
        "$THEME"/scalable/places/default-*.svg || return 1

    sed  -i "s/#b29aff/$(rgb_value "$COLORS_VARIANT" +20)/gi" \
        "$THEME"/scalable/places/default-*.svg || return 1

    sed  -i "s/#5294E2/$COLORS_VARIANT/gi" \
        "$THEME"/16/places/folder*.svg || return 1
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


install_dunst_colors() {
    local CFG="$HOME/.config"

    export URGENCY_LOW="#D6AF86"
    export URGENCY_NORMAL="#90A57E"
    export URGENCY_CRITICAL="#A26666"

    if apply "${TEMPLATES}/dunstrc" "$CFG/dunst/dunstrc"; then
        killall dunst 2>/dev/null
        return 0
    fi

    return 1
}
