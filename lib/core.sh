#!/usr/bin/env bash
[[ ${CORE_LIB_LOADED} ]] && exit 0 || CORE_LIB_LOADED=true

LC_ALL=C

source "$(dirname "${0/\~/$HOME}")/math.sh"


declare COLOR_KEYS=(
    0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    foreground
    background
    selection_foreground
    selection_background
    cursor
    url_color
    highlight
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

xrdbq() {
    xrdb -query | grep -w "${1}:" | cut -f 2
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
			color=$(get 2)
			;;
		highlight)
			color=$(get 9)
			;;
		url_color)
			color=$(get 12)
			;;
		selection_foreground)
			[[ ${GTK_APPLICATION_PREFER_DARK_THEME:-1} == 1 ]] \
				&& color=$(get 0) \
				|| color=$(get 7)
			;;
		selection_background)
			[[ ${GTK_APPLICATION_PREFER_DARK_THEME:-1} == 1 ]] \
				&& color=$(get 7) \
				|| color=$(get 0)
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
ecolor() {
    printf "\033[48;2;%03d;%03d;%03dm" $(rgb ${1}) 
    echo -en "#\033[0m"
    printf "\033[38;2;%03d;%03d;%03dm" $(rgb ${1}) 
    echo -en "${1:1}\033[0m"
}

preview() {
    local name="${1:-xrdb}"
    local len=$(echo "70 - ${#name} - 4" | bc -s)

    echo -en $(printf '─%.0s' $(seq $len)); echo -e "[ ${name} ]"
    echo -e  "  BLK      RED      GRN      YEL      BLU      MAG      CYN      WHT"
    echo -e  "$(printf '─%.0s' {1..70})"

    for i in {0..7}; do
        printf "\033[38;2;%03d;%03d;%03dm" $(rgb ${COLOR[$i]}) 
        echo -en "$([[ $i -gt 0 ]] && echo "  ")${COLOR[$i]}"
    done
    echo -e "\033[0m"

    for i in {8..15}; do
        printf "\033[38;2;%03d;%03d;%03dm" $(rgb ${COLOR[$i]}) 
        echo -en "$([[ $i -gt 8 ]] && echo "  ")${COLOR[$i]}"
    done
    echo -e "\033[0m"

    echo -e "$(printf '─%.0s' {1..70})"
}

preview_theme() {
	NAME="${1:-xrdb}"
		printf "%-15s%s\n"      "Path:"         "${NAME/$HOME/\~}"

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
}








set_timer

echo "get_color_key balck:          $(get_color_key black)"
echo "get_color_key red-light:      $(get_color_key red-light)"
echo "get_color_key 1:              $(get_color_key 1)"
echo "get_color_key 200:            $(get_color_key 200)"
echo "get_color_key cursor:         $(get_color_key cursor)"
echo "get_color_key Foreground:     $(get_color_key Foreground)"
echo "get_color_key 0 any:          $(get_color_key '0 background')"

COLOR[1]=#AABBCC
echo "get 1:" $(get 1)
echo "get 9:" $(get 9)

#restore_colors_from_xrdb
echo "get 1:" $(get 1)
echo "get 9:" $(get 9)

preview_theme
preview

displaytime $(get_timer)
