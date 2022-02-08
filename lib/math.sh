#!/usr/bin/env bash

LC_ALL=C

source "$(dirname "${0/\~/$HOME}")/notify.sh"


# -----------------------------------------------------------------------------
# Math and types utilites
# -----------------------------------------------------------------------------
re_int="^[-+]?[0-9]+$"
re_flt="^[-+]?[0-9]+(\.)?[0-9]*$"
re_pct="^[-+]?[0-9]+(\.)?[0-9]*\%$"

isvalue() {
    [[ "${1}" =~ $re_flt || "${1}" =~ $re_pct ]]
}

value() {
    if isvalue "${1}"; then
        echo $(float "${1}") \
            $([[ "${1}" =~ ^[\+\-]{1} ]] && echo -n ' rel' || echo -n ' abs') \
            $([[ "${1}" =~ $re_pct ]] && echo -n ' %')
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
        echo ${1/+/} | sed 's/\..*$//g' && return

    fatal "Not integer value cast: '${1}'"
    return 1
}

isfloat() {
    [[ "${1}" =~ $re_flt ]]
}

float() {
    isvalue "${1}" && \
        echo ${1/+/} | sed 's/\%$//g' && return

    fatal "Not float value cast: '${1}'"
    return 1
}

round() {
    local val=$(float "${1}")
    local acc=$(int "${2:-0}")
    printf "%.${acc}f\n" "$val" 2>/dev/null || return 1
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

at() {
    local value=${1:-undefined}
    shift

    [[ " ${@} " == *" $value "* ]]
}

grad() {
    local val=$(int "${1}")

    [[ $val -eq 0 ]] && val=0

    echo $(( $val % 360 ))
}

ugrad() {
    local val=$(grad ${1})

    [[ $val -lt 0 ]] && \
        echo $(( 360 + $val )) || echo $val
}

min() {
    local MIN
    local next

    for next in ${@}; do
        [[ ! ${MIN} ]] && \
            MIN=$(int ${next}) && continue

        next=$(int ${next})
        [[ $next && "$next" -lt "$MIN" ]] && \
            MIN=${next}
    done

    echo "${MIN}"
}

max() {
    local MAX
    local next

    for next in ${@}; do
        [[ ! ${MAX} ]] && \
            MAX=$(int ${next}) && continue

        next=$(int ${next})
        [[ $next && "$next" -gt "$MAX" ]] && \
            MAX=${next}
    done

    echo "${MAX}"
}

# -----------------------------------------------------------------------------
# Colors functions
# -----------------------------------------------------------------------------
re_xrgb="^#[A-Fa-f0-9]{6}$"

isrgb() {
    [[ "${1}" =~ $re_xrgb ]]
}

rgb() {
    local val=$(isrgb ${1%.*})

    [[ ${val} ]] && \
        echo $val && return

    fatal "Invalid #RGB color: '${1}'"
}

byte() {
    local val=$(int "${1}")

    [[ ${1} -lt   0 ]] && val=0
    [[ ${1} -gt 255 ]] && val=255
    echo "$val"
}



INTERUPT_IS_FATAL=false
HEADER='$LABEL '

i1="123"
i2="123z"
f1="123.1231231"
f2="112.12312x"
p1="123.1231231%"
p2="123.12312z%"

echo "--------------------"
isfloat $f1 && success "OK" || error "ERROR"
isfloat $f2 && success "OK" || error "ERROR"

echo "--------------------"
float $i1
float $i2
float $f1
float $f2
float $p1
float $p2

echo "--------------------"
bool "" && echo "true" || echo "false"
bool "1" && echo "true" || echo "false"
bool "0" && echo "true" || echo "false"
bool "fuck" && echo "true" || echo "false"
bool "$HEADER" && echo "Header present" || echo "$HEADER"

echo "--------------------"
value $i1
value $i2
value $f1
value $f2
value $p1
value $p2
value "+$p1"
value "-$p1"
value "-$p2"
