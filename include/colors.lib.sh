
# require: errors.lib.sh

declare -A COLOR


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


int() {
    local value
    printf -v value "%d" ${1/+/} > /dev/null 2>&1
    [[ ${value} && ${value} == ${1/+/} ]] && \
        echo $value
}


at() {
    local value=${1:-undefined}; shift
    [[ " ${@} " == *" $value "* ]] && \
        echo true
}


xrdbq() {
    xrdb -query | grep -w "${1}:" | cut -f 2
}


__rgba_parser() {
    local RGBA="${1}"

    [[ ${#RGBA} == 7 ]] && RGBA="${RGBA}FF"

    if ! [[ ${#RGBA} != 7 && ${#RGBA} != 9 &&  ${RGBA:0:1} != "#" ]]; then
        printf -v RGBA "%d %d %d %d" 0x${RGBA:1:2} 0x${RGBA:3:2} 0x${RGBA:5:2} 0x${RGBA:7:2} > /dev/null 2>&1 && \
        echo -e ${RGBA} && return
    fi

    [[ ! "${2}" ]] && \
        fatal "Invalid color '${1}'"
}


format() {
    local RGBA=( $(__rgba_parser "${2}" "${3}") )
    [[ ! ${RGBA} ]] && return

    local r=${RGBA[0]}                          # integer 0..255
    local g=${RGBA[1]}                          # integer 0..255
    local b=${RGBA[2]}                          # integer 0..255
    local a=${RGBA[3]}                          # integer 0..255

    local R=$(printf "%02X" $r)                 # hex 00..FF
    local G=$(printf "%02X" $g)                 # hex 00..FF
    local B=$(printf "%02X" $b)                 # hex 00..FF
    local A=$(printf "%02X" $a)                 # hex 00..FF

    local alpha=$(echo "$a / 255" | bc -l)      # float 0.0 - 1.0

    alpha=${alpha:0:6}
    eval "echo -e \"${1}\""
}


ebg() {
    local color=${1}; shift
    echo -en "\033[$(
        printf "48;2;%03d;%03d;%03d" $(format '$r $g $b' "${color}")
    )m"
    echo -en "${@}"
}

efg() {
    local color=${1}; shift
    echo -en "\033[$(
        printf "38;2;%03d;%03d;%03d" $(format '$r $g $b' "${color}")
    )m"
    echo -en "${@}"
}

ers() {
    echo -en "\033[0m"
    echo -en "${@}"
}


saturation() {
    local RGB=( $(format '$r $g $b $A' "${1}") )
    local r=${RGB[0]}
    local g=${RGB[1]}
    local b=${RGB[2]}
    local ALPHA=${RGB[3]}
    local value=$(int "${2}")

    [[ ! ${value} ]] && ERROR=true

    if [[ $r -eq 0 && $g -eq 0 && $b -eq 0 ]]; then
        r=1; g=1; b=1
    fi

    local max=$r
    [[ $g -gt $max ]] && max=$g
    [[ $b -gt $max ]] && max=$b

    local v=$(echo "$max / 255 * 100" | bc -l)
    local value=$(echo "$v + $value" | bc -l)

    if [[ ! ${ERROR} && ${value} ]]; then
        r=$(echo "($r / $v * $value)" | bc -l 2>/dev/null); r=${r%.*}
        [[ $r -gt 255 ]] && r=255
        [[ $r -lt 0 ]]   && r=0

        g=$(echo "($g / $v * $value)" | bc -l 2>/dev/null); g=${g%.*}
        [[ $g -gt 255 ]] && g=255
        [[ $g -lt 0 ]]   && g=0

        b=$(echo "($b / $v * $value)" | bc -l 2>/dev/null); b=${b%.*}
        [[ $b -gt 255 ]] && b=255
        [[ $b -lt 0 ]]   && b=0
    fi

    [[ ! ${ERROR} ]] && \
        printf "#%02X%02X%02X%s" $r $g $b "$ALPHA" && return

    fatal "Invalid color '${1}'"
}


fill_special_colors() {
    [[ ${COLOR[foreground]} ]]           || COLOR[foreground]=${COLOR[15]:-#FFFFFF}
    [[ ${COLOR[background]} ]]           || COLOR[background]=${COLOR[0]:-#000000}
    [[ ${COLOR[cursor]} ]]               || COLOR[cursor]=${COLOR[8]:-#FFFFFF}
    [[ ${COLOR[highlight]} ]]            || COLOR[highlight]=${COLOR[9]:-#FF0000}
    [[ ${COLOR[url_color]} ]]            || COLOR[url_color]=${COLOR[12]:-#0000FF}
    [[ ${COLOR[selection_foreground]} ]] || COLOR[selection_foreground]=${COLOR[0]:-#000000}
    [[ ${COLOR[selection_background]} ]] || COLOR[selection_background]=${COLOR[7]:-#FFFFFF}
}
