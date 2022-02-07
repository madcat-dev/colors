#!/usr/bin/env bash

LC_ALL=C

source "$(dirname $0)/notify.sh"

re_int="^[-+]?[0-9]+$"
re_float="^[-+]?[0-9]+(\.)?[0-9]*$"
re_pc="^[-+]?[0-9]+(\.)?[0-9]*\%$"
re_color="^#[A-Fa-f0-9]{6}$"

# -----------------------------------------------------------------------------
# Math and types utilites
# -----------------------------------------------------------------------------

isvalue() {
    [[ "${1}" =~ $re_float || "${1}" =~ $re_pc ]]
}

value() {
    local md="abs"d

    if [[ "+-" == *"${1[0]}"* ]]; then 
		md="rel"
	fi
    isvalue "${1}" && printf "%s %s %s" \
        "$(float ${1})" \
        $([[ "+-" == *"${1[0]}"* ]] && echo rel || echo abs) \
        $([[ "${1}" =~ $re_pc ]] && echo '%') \
        return 0

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
    [[ "${1}" =~ $re_float ]]
}

float() {
    isvalue "${1}" && \
        echo ${1/+/} | sed 's/\%$//g' && return

    fatal "Not float value cast: '${1}'"
    return 1
}


NOTIFY_RGB_COLORS=true
INTERUPT_IS_FATAL=false

i1="123"
i2="123z"
f1="123.1231231"
f2="112.12312x"
p1="123.1231231%"
p2="123.12312z%"

isfloat $f1 && success "OK" || error "ERROR"
isfloat $f2 && success "OK" || error "ERROR"

float $i1
float $i2
float $f1
float $f2
float $p1
float $p2

bool "" && echo "true" || echo "false"
bool "1" && echo "true" || echo "false"
bool "0" && echo "true" || echo "false"
bool "fuck" && echo "true" || echo "false"
bool "$HEADER" && echo "Header present" || echo "$HEADER"
