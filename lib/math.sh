#!/usr/bin/env bash
[[ ${MATH_LIB_LOADED} ]] && return 0 || MATH_LIB_LOADED=true

LC_ALL=C

source "$(dirname "${0/\~/$HOME}")/notify.sh"


# -----------------------------------------------------------------------------
# Math and types utilites
# -----------------------------------------------------------------------------
re_int="^[-+]?[0-9]+$"
re_flt="^[-+]?[0-9]+(\.)?[0-9]*$"
re_pct="^[-+]?[0-9]+(\.)?[0-9]*\%$"

bool() {
    [[ "${1,,}" =~ ^0|no|off|false$ ]] && return 1
    [[ "${1}" ]]
}

isvalue() {
    [[ "${1}" =~ $re_flt || "${1}" =~ $re_pct ]]
}

value() {
    local v m p

    if isvalue "${1}"; then
        if [[ "${1}" =~ $re_pct ]]; then
            v=$(float "${1}")
            p='%'
        else
            v=$(int "${1}")
        fi

        [[ "${1}" =~ ^[\+\-]{1} ]] && m='rel' || m='abs'

        echo "$v $m $p"
        return 0
    fi

    fatal "Not parsed value: '${1}'"
    return 1
}

isint() {
    [[ "${1}" =~ $re_int ]]
}

int() {
    isvalue "${1}" && \
        echo ${1/+/} | sed 's/\..*$//g' && \
        return 0

    fatal "Not integer value cast: '${1}'"
    return 1
}

isfloat() {
    [[ "${1}" =~ $re_flt ]]
}

float() {
    isvalue "${1}" && \
        echo ${1/+/} | sed 's/\%$//g' && \
        return 0

    fatal "Not float value cast: '${1}'"
    return 1
}

round() {
    local val=$(float "${1}")
    local acc=$(int "${2:-0}")
    printf -v val "%.${acc}f" "$val" 2>/dev/null && \
        echo "$val"
}

floor() {
    local val=$(float "${1}")
    val=( ${val/./ } )

    [[ ${val[0]} -lt 0 && ${val[1]} -gt 0 ]] && \
        echo $(( $val - 1 )) || echo "$val"
}

ceil() {
    local val=$(float "${1}")
    val=( ${val/./ } )

    [[ ${val[0]} -ge 0 && ${val[1]} -gt 0 ]] && \
        echo $(( $val + 1 )) || echo $val
}

min() {
    local MIN next

    for next in ${@}; do
        [[ ! ${MIN} ]] && \
            MIN=$(int ${next}) && \
            continue

        next=$(int ${next})
        [[ $next && "$next" -lt "$MIN" ]] && \
            MIN=${next}
    done
    echo "${MIN}"
}

max() {
    local MAX next

    for next in ${@}; do
        [[ ! ${MAX} ]] && \
            MAX=$(int ${next}) && \
            continue

        next=$(int ${next})
        [[ $next && "$next" -gt "$MAX" ]] && \
            MAX=${next}
    done
    echo "${MAX}"
}

byte() {
    local val=$(int "${1}")
    [[ ${1} -lt   0 ]] && val=0
    [[ ${1} -gt 255 ]] && val=255
    echo "$val"
}

grad() {
    local val
    val=$(int "${1}") && \
        echo $(( $val % 360 ))
}

ugrad() {
    local val=$(grad ${1})

    [[ $val -lt 0 ]] && \
        echo $(( 360 + $val )) || echo $val
}

# -----------------------------------------------------------------------------
# Colors functions
# -----------------------------------------------------------------------------
re_xrgb='^#[A-Fa-f0-9]{6}$'

isrgb() {
    [[ "${1}" =~ $re_xrgb ]]
}

rgb() {
    printf -v RGB "%d %d %d" \
        0x${1:1:2} 0x${1:3:2} 0x${1:5:2} 2>/dev/null && \
        echo "$RGB" && \
        return 0

    fatal "Invalid #RGB color: '${1}'"
    return 1
}

rgb_to_hex() {
    printf "#%02X%02X%02X\n" \
        $(byte ${1:-0}) $(byte ${2:-0}) $(byte ${3:-0})
}

rgb_to_hsv() {
    local RGB=( $(rgb "${1}") )
    local r=${RGB[0]}  # integer 0..255
    local g=${RGB[1]}  # integer 0..255
    local b=${RGB[2]}  # integer 0..255

    local maxc=$(max $r $g $b)
    local minc=$(min $r $g $b)

    # Value: color brightness {0..100}
    local v=$(round $(echo "$maxc / 2.55" | bc -l))

    [[ "$minc" == "$maxc" ]] && \
        echo "0 0 $v" && return

    # Saturation: color saturation ("purity") {0..100}
    local s=$(round $(echo "($maxc - $minc) / $maxc * 100" | bc -l))

    # Hue: position in the spectrum {0..360}
    local h=0
    local rc=$(echo "($maxc - $r) / ($maxc - $minc)" | bc -l)
    local gc=$(echo "($maxc - $g) / ($maxc - $minc)" | bc -l)
    local bc=$(echo "($maxc - $b) / ($maxc - $minc)" | bc -l)

    if [[ $r == $maxc ]]; then
        h=$(echo "$bc - $gc" | bc -l)
    elif [[ $g == $maxc ]]; then
        h=$(echo "2.0 + $rc - $bc" | bc -l)
    else
        h=$(echo "4.0 + $gc - $rc" | bc -l)
    fi

    h=$(round $(echo "($h / 6.0) * 360" | bc -l))

    echo "$h $s $v"
}

hsv_to_rgb() {
    local h=$(ugrad "${1}")
    local s=$(int "${2}")
    local v=$(int "${3}")

    if [[ $s -lt 0 || $s -gt 100 ]]; then
        fatal "Invalid saturation value"
    fi

    v=$(round $(echo "$v * 2.55" | bc -l))
    [[ $s -eq 0 ]] && \
        rgb_to_hex $v $v $v && return

    h=$(echo "$h / 360" | bc -l)
    s=$(echo "$s / 100" | bc -l)

    local i=$(floor $(echo "$h * 6.0" | bc -s)) # XXX assume int() truncates!
    local f=$(echo "$h * 6.0 - $i" | bc -l)
    local p=$(round $(echo "$v * (1.0 - $s)" | bc -l))
    local q=$(round $(echo "$v * (1.0 - $s * $f)" | bc -l))
    local t=$(round $(echo "$v * (1.0 - $s * (1.0 - $f))" | bc -l))

    i=$(( $i % 6 ))

    [[ $i -eq 0 ]] && \
        rgb_to_hex $v $t $p && return
    [[ $i -eq 1 ]] && \
        rgb_to_hex $q $v $p && return
    [[ $i -eq 2 ]] && \
        rgb_to_hex $p $v $t && return
    [[ $i -eq 3 ]] && \
        rgb_to_hex $p $q $v && return
    [[ $i -eq 4 ]] && \
        rgb_to_hex $t $p $v && return
    [[ $i -eq 5 ]] && \
        rgb_to_hex $v $p $q && return

    fatal "Error of hsv conversion"
}


rgb_hue() {
    local HSV=( $(rgb_to_hsv "${1}") )
    local h=${HSV[0]}
    local val=( $(value "${2}") )
    local delta=${val[0]}

    # percent value
    if [[ ${val[2]} ]]; then
		delta=$(round $(echo "$h / 100 * ${val[0]}" | bc -l))
	fi

    # absolute value
    [[ "${val[1]}" == "abs" ]] && \
        delta=$(( $delta - $h ))

    hsv_to_rgb \
        $(( $h + $delta )) ${HSV[1]} ${HSV[2]} 
}

rgb_saturation() {
    local HSV=( $(rgb_to_hsv "${1}") )
    local s=${HSV[1]}
    local val=( $(value "${2}") )
    local delta=$(int ${val[0]})

    # percent value
    if [[ ${val[2]} ]]; then
        delta=$(round $(echo "$s / 100 * ${val[0]}" | bc -l))
	fi

    # absolute value
    [[ "${val[1]}" == "abs" ]] && \
        delta=$(( $delta - $s ))

    s=$(( $s + $delta ))
    [[ $s -lt   0 ]] && s=0
    [[ $s -gt 100 ]] && s=100

    hsv_to_rgb \
        ${HSV[0]} $s ${HSV[2]} 
}

rgb_value() {
    local HSV=( $(rgb_to_hsv "${1}") )
    local v=${HSV[2]}
    local val=( $(value "${2}") )
    local delta=$(int ${val[0]})

    # percent value
    if [[ ${val[2]} ]]; then
        delta=$(round $(echo "$v / 100 * ${val[0]}" | bc -l))
	fi

	# absolute value
    [[ "${val[1]}" == "abs" ]] && \
        delta=$(( $delta - $v ))

    v=$(( $v + $delta ))
    [[ $v -lt   0 ]] && s=0
    [[ $v -gt 100 ]] && s=100

    hsv_to_rgb \
        ${HSV[0]} ${HSV[1]} $v
}

rgb_inverse() {
    local RGB=( $(rgb "${1}") )

    rgb_to_hex \
        $(( 255 - ${RGB[0]} )) \
        $(( 255 - ${RGB[1]} )) \
        $(( 255 - ${RGB[2]} ))
}

