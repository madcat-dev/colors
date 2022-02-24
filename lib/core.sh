#!/usr/bin/env bash
[[ ${CORE_LIB_LOADED} ]] && return 0 || CORE_LIB_LOADED=true

LC_ALL=C

BASE=$(realpath $(dirname ${BASH_SOURCE})/..)
CACHE="$HOME/.cache/colors"

mkdir -p "$CACHE" > /dev/null 2>&1

source $BASE/lib/rgb.sh

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
    [black]=0  [red]=1	   [green]=2  [yellow]=3
    [blue]=4   [magenta]=5  [cyan]=6   [white]=7
)

declare -A COLOR


# -----------------------------------------------------------------------------
# Another access functions
# -----------------------------------------------------------------------------

xrdbq() {
    xrdb -query | grep -w "${1}:" | cut -f 2
}

get_wal() {
    tail -n1 "${HOME}/.fehbg" \
        | awk '{print $NF}' \
        | sed "s/'//g"
}

get_gtk_setting() {
    gtk-query-settings \
        | grep -w ${1}: \
        | sed 's/^.*\:\ *//g' \
        | sed 's/"//g'
}

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


# -----------------------------------------------------------------------------
# Color access functions
# -----------------------------------------------------------------------------

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
			isint "$KEY" \
				&& color=${COLOR[$(( $KEY - 8 ))]}
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

preview_header() {
	local name="${1:-xrdb}"
    local wall="$(get_wal)"

	echo -e "Path:        ${name/$HOME/\~}"
    echo -e "Wallpaper:   ${wall/$HOME/\~}"
    echo -e "Gtk theme:   ${GTK_THEME_NAME:-...} [$(get_gtk_setting gtk-theme-name)]"
    echo -e "Icons theme: ${GTK_ICON_THEME_NAME:-...} [$(get_gtk_setting gtk-icon-theme-name)]"
    echo -e "Font name:   ${GTK_FONT_NAME:-...} [$(get_gtk_setting gtk-font-name)]"

    eline "─" 70

	echo -e "background: $(ecolor $(get background) $(get foreground))"
    echo -e "foreground: $(ecolor $(get foreground) $(get background))"
    echo -e "cursor:     $(ecolor $(get cursor)     $(get background))"
}


# -----------------------------------------------------------------------------
# Operation functions
# -----------------------------------------------------------------------------

apply() {
    local data
    local SRCE="${1/\~/$HOME}"
    local DEST="${2/\~/$HOME}"

    if [[ ! -f "$SRCE" ]]; then
        error "Template '${SRCE/$HOME/\~}' not existing!"
        return 1
    fi

    rm    -f "$DEST" > /dev/null 2>&1
    mkdir -p "$(dirname "${DEST}")" > /dev/null 2>&1

    while read -r data; do
        local IFS=$'\x1B'

        data="${data//\\/\\x5C}"
        data="${data//\"/\\x22}"
        data=$'\x22'$data$'\x22'

        eval echo -e ${data} >> $DEST 2>/dev/null \
            || return 1
    done < $SRCE
}

gen_colors_from_image() {
	local light="$(bool ${2})"
	local c index=1

	if ! type -p convert >/dev/null 2>&1; then
		fatal "imagemagick not found"
		exit 1
	fi

	c=($(convert "${1}" +dither -colors 16 -unique-colors txt:- | grep -E -o " \#.{6}"))

	# color 0
	[[ "$light" ]] \
		&& echo ${c[$((${#c[@]} - 1))]} \
		|| echo ${c[0]}
	# colors 1..6
	for i in {0..5}; do
		echo ${c[$((${#c[@]} - 8 + $i))]}
	done
	# color 7
	[[ "$light" ]] \
		&& echo ${c[0]} \
		|| echo ${c[$((${#c[@]} - 1))]}
}

colors_reallocation() {
	local light="$(bool ${1})"
    local HSV=( $(rgb_to_hsv $(get 0)) )
    local v=${HSV[2]}

    if [[ "$light" ]]; then
        if [[ ! ${COLOR[background]} ]]; then
            [[ $v -gt 75 ]] \
                && COLOR[0]=$(rgb_value $(get 0) 75)

            COLOR[background]=$(rgb_value $(get 0) +10)
        fi

        COLOR[8]=$(rgb_value $(get 0) -20)
	fi

    if [[ ! "$light" ]]; then
        if [[ ! ${COLOR[background]} ]]; then
            [[ $v -lt 25 ]] \
                && COLOR[0]=$(rgb_value $(get 0) 25)

            COLOR[background]=$(rgb_value $(get 0) -10)
        fi

        COLOR[8]=$(rgb_value $(get 0) +20)
    fi

    for i in {1..7}; do
        COLOR[$(($i + 8))]=$(rgb_value $(get $i) +10)
    done
}
