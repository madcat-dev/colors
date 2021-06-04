
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
        echo $value || echo ""
}


at() {
    local value=${1:-undefined}; shift

    while [ -n "$1" ]; do
        [[ "$value" == "$1" ]] && \
            echo "true" && break
        shift
    done
}


xrdbq() {
    xrdb -query | grep -w "${1}:" | cut -f 2
}


rgb() {
    local RGB=( $(rgba "${1}" "${2}") )

    [[ ${RGB_STRONG} && ${#1} != 7 ]] && \
        echo -e "\033[31mInvalid rgb color '${1}', terminate\033[0m" >&2 && \
        kill $$

    echo "${RGB[0]} ${RGB[1]} ${RGB[2]}"
    return
}

rgba() {
    local RGBA="${1}"

    [[ ${#RGBA} == 7 ]] && RGBA="${RGBA}FF"

    if ! [[ ${#RGBA} != 7 && ${#RGBA} != 9 &&  ${RGBA:0:1} != "#" ]]; then
        printf -v RGBA "%d %d %d %d" 0x${RGBA:1:2} 0x${RGBA:3:2} 0x${RGBA:5:2} 0x${RGBA:7:2} > /dev/null 2>&1 && \
        echo -e ${RGBA} && return
    fi

    [[ ! "${2}" ]] && \
        echo -e "\033[31mInvalid color '${1}', terminate\033[0m" >&2 && \
        kill $$
}


rgb_format() {
    local RGBA=( $(rgba "${2}") )
    local r=${RGBA[0]}
    local g=${RGBA[1]}
    local b=${RGBA[2]}
    local a=${RGBA[3]}
    local R=$(printf "%02X" $r)
    local G=$(printf "%02X" $g)
    local B=$(printf "%02X" $b)
    local A=$(printf "%02X" $a)
    local alpha=$(echo "$a / 255" | bc -l)

    alpha=${alpha:0:6}
    eval "echo -e \"${1}\""
}


rgb_escapes() {
    printf "%03d:%03d:%03d" $(rgb "${1}")
    return
}


rgb_normalize() {
    for i in ${COLOR_KEYS[@]}; do
        [[ "${COLOR[$i]}" ]] && \
            COLOR[$i]="$(rgb_format '#${R}${G}${B}' "${COLOR[$i]}")"
    done
}

rgba_normalize() {
    for i in ${COLOR_KEYS[@]}; do
        [[ "${COLOR[$i]}" ]] && \
            COLOR[$i]="$(rgb_format '#${R}${G}${B}${A}' "${COLOR[$i]}")"
    done
}


saturation() {
    local RGB=( $(rgb "${1}") )
    local ALPHA=${1:7:2}
    local r=${RGB[0]}
    local g=${RGB[1]}
    local b=${RGB[2]}
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

    echo -e "\033[31mInvalid color '${1}', terminate\033[0m" >&2 && \
        kill $$
}

ecolor() {
    echo -en "\033[48:2:$(rgb_escapes "${1}")m#\033[0m"
    echo -en "\033[38:2:$(rgb_escapes "${1}")m${1:1}\033[0m"
}

