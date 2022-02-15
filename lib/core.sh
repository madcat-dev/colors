#!/usr/bin/env bash
[[ ${CORE_LIB_LOADED} ]] && exit 0 || CORE_LIB_LOADED=true

LC_ALL=C
declare -A COLOR
declare -A COLOR_WORDS

source "$(dirname "${0/\~/$HOME}")/math.sh"


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

COLOR_WORDS=(
    [black]=0       [blacklight]=8      [lightblack]=8      [blackbright]=8
    [red]=1         [redlight]=9        [lightred]=9        [redbright]=9
    [green]=2       [greenlight]=10     [lightgreen]=10     [greenbright]=10
    [yellow]=3      [yellowlight]=11    [lightyellow]=11    [yellowbright]=11
    [blue]=4        [bluelight]=12      [lightblue]=12      [bluebright]=12
    [magenta]=5     [magentalight]=13   [lightmagenta]=13   [magentabright]=13
    [cyan]=6        [cyanlight]=14      [lightcyan]=14      [cyanbright]=14
    [white]=7       [whitelight]=15     [lightwhite]=15     [whitebright]=15
)

get_color_key() {
    local KEY=( ${1,,} )
    local REKEY=$(echo "$KEY" | sed 's/[^a-z]//g')

    [[ "${COLOR_WORDS[$REKEY]}" ]] 2>/dev/null && \
        KEY=${COLOR_WORDS[$REKEY]}

    [[ ${#KEY[@]} -eq 1 && " ${COLOR_KEYS[@]} " == *" $KEY "* ]] && \
        echo "$KEY" || echo "UNDEFINED"
}

get() {
    local KEY=$(get_color_key "${1}")
    local color="${COLOR[$KEY]}"

    isrgb "$color" && \
        echo "$color" && return

    fatal "Color '${1}' invalid or not existing"
}

echo "get_color_key balck:          $(get_color_key black)"
echo "get_color_key red-light:      $(get_color_key red-light)"
echo "get_color_key 1:              $(get_color_key 1)"
echo "get_color_key 200:            $(get_color_key 200)"
echo "get_color_key cursor:         $(get_color_key cursor)"
echo "get_color_key Foreground:     $(get_color_key Foreground)"
echo "get_color_key 0 any:          $(get_color_key '0 background')"