#!/usr/bin/env bash
[[ ${CORE_LIB_LOADED} ]] && return 0 || CORE_LIB_LOADED=true

LC_ALL=C

BASE=$(realpath $(dirname $0)/..)

source "$BASE/lib/estimate.sh"


# -----------------------------------------------------------------------------
# Declarations
# -----------------------------------------------------------------------------

declare COLOR_KEYS=(
    0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    foreground
    background
    cursor
)

declare -A COLOR_WORDS=(
    [black]=0       [blacklight]=8      [lightblack]=8      [blackbright]=8
    [red]=1         [redlight]=9        [lightred]=9        [redbright]=9
    [green]=2       [greenlight]=10     [lightgreen]=10     [greenbright]=10
    [yellow]=3      [yellowlight]=11    [lightyellow]=11    [yellowbright]=11
    [blue]=4        [bluelight]=12      [lightblue]=12      [bluebright]=12
    [magenta]=5     [magentalight]=13   [lightmagenta]=13   [magentabright]=13
    [cyan]=6        [cyanlight]=14      [lightcyan]=14      [cyanbright]=14
    [white]=7       [whitelight]=15     [lightwhite]=15     [whitebright]=15
)

declare -A COLOR


# -----------------------------------------------------------------------------
# Color access functions
# -----------------------------------------------------------------------------

#xrdbq() {
    #xrdb -query | grep -w "${1}:" | cut -f 2
#}

get_wal() {
    tail -n1 "${HOME}/.fehbg" \
        | awk '{print $NF}' \
        | sed "s/'//g"
}

get_gtk_setting() {
    gtk-query-settings \
        | grep -w ${1}: \
        | sed 's/^.*\://g' \
        | sed 's/"//g'
}


# -----------------------------------------------------------------------------
# Color access functions
# -----------------------------------------------------------------------------

restore_colors_from_xrdb() {
	local color i

	for i in ${COLOR_KEYS[@]}; do
		isint $i \
			&& color=$(xrdbq "color$i") \
			|| color=$(xrdbq "*.$i")

		if [[ "$color" ]]; then
			isrgb "$color" \
				|| fatal "Invalid imported color '$i' from xrdb"

			COLOR[$i]="$color"
		fi
	done
}

get_color_key() {
    local KEY=( ${1,,} )
    local REKEY=$(echo "$KEY" | sed 's/[^a-z]//g')

    [[ "${COLOR_WORDS[$REKEY]}" ]] 2>/dev/null \
		&& KEY=${COLOR_WORDS[$REKEY]}

    [[ ${#KEY[@]} -eq 1 && " ${COLOR_KEYS[@]} " == *" $KEY "* ]] \
		&& echo "$KEY" \
		|| echo "UNDEFINED"
}

get() {
    local KEY=$(get_color_key "${1}")
    local color="${COLOR[$KEY]}"

	if [[ "$color" ]]; then
		isrgb "$color" \
			&& echo "$color" && return

		fatal "Invalid stored '${1}' color"
	fi

	case "$KEY" in
		foreground)
			color=$(get 7)
			;;
		background)
			color=$(get 0)
			;;
		cursor)
			color="#FFA500"
            ;;
		*)
			isint "$KEY" || break

			if [[ $KEY -eq 8 ]]; then
				color=$(rgb_value ${COLOR[0]} +20%)

			elif [[ $KEY -ge 9 && $KEY -le 15 ]]; then
				color=${COLOR[$(( $KEY - 8 ))]}

			fi
			;;
	esac

	isrgb "$color" \
		&& echo $color && return

    fatal "Color '${1}' invalid or not existing"
}


# -----------------------------------------------------------------------------
# Preview functions
# -----------------------------------------------------------------------------

setfg() {
    printf "\033[38;2;%03d;%03d;%03dm" $(rgb ${1}) 
}

setbg() {
    printf "\033[48;2;%03d;%03d;%03dm" $(rgb ${1}) 
}

res() {
    echo -en "\033[0m"
}

ecolor() {
    [[ "${2}" ]] \
        && echo -en "$(setbg ${2})"
    echo -en "$(setfg ${1})${1}$(res)"
}

eline() {
    local def="─"
    local sep="${1:-$def}"
    local len=$(( ${2:-70} - ${#3} ))

    printf "${sep}%.0s" $(seq $len)
    echo -e "${3}"
}

preview() {
    local name="${1:-xrdb}"

    eline "─" 70 "[ ${name} ]"
    echo -e "  BLK      RED      GRN      YEL      BLU      MAG      CYN      WHT"
    eline "─" 70

    for i in {0..15}; do
        ecolor $(get $i)
        [[ $i == 7 || $i == 15 ]] \
            && echo || echo -n "  "
    done
    eline "─" 70
}

preview_theme() {
	local name="${1:-xrdb}"

	printf "%-15s%s\n" "Path:" "${name/$HOME/\~}"

    echo -e "Gtk theme:   ${GTK_THEME_NAME:-...} [$(get_gtk_setting gtk-theme-name)]"
    echo -e "Icons theme: ${GTK_ICON_THEME_NAME:-...} [$(get_gtk_setting gtk-icon-theme-name)]"
    echo -e "Font name: ${GTK_FONT_NAME:-...} [$(get_gtk_setting gtk-font-name)]"

    eline "─" 70

	echo -e "background: $(ecolor $(get background) $(get foreground))"
    echo -e "foreground: $(ecolor $(get foreground) $(get background))"
    echo -e "cursor:     $(ecolor $(get cursor)     $(get background))"
}


# -----------------------------------------------------------------------------
# 
# -----------------------------------------------------------------------------

apply() {
    local data
    local SRCE="${1/\~/$HOME}"
    local DEST="${2/\~/$HOME}"

    if [[ ! -f "$SRCE" ]]; then
        error "- Template '${SRCE/$HOME/\~}' not existing!"
        return 1
    fi

    rm    -f "$DEST" > /dev/null 2>&1
    mkdir -p "$(dirname "${DEST}")" > /dev/null 2>&1

    while read -r data; do
        local IFS=$'\x1B'

        data="${data//\"/\\x22}"
        data="${data//\\/\\x5C}"
        data=$'\x22'$data$'\x22'

        echo -e "$(eval echo -e ${data})" >> $DEST 2>/dev/null \
            || return 1
    done < $SRCE
}



INTERUPT_IS_FATAL=true


set_timer

restore_colors_from_xrdb

source $BASE/themes/mars

preview_theme
preview

apply "$BASE/templates/gtksourceview.xml" "/tmp/gtksourceview.xml"
#apply "$BASE/templates/gtksourceview.xml" "/tmp/gtksourceview.xml"

#data="\$(rgb_value \${COLOR[1]} 10)"
#data="$(eval echo -e ${data})"
#echo "-->>$data"

debug "FUCK"
info  "FUCK"
DEBUG_LEVEL=0
debug "ANY FUCK"

displaytime $(get_timer)
