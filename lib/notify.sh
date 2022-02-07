#!/usr/bin/env bash

LC_ALL=C

bool() {
    [[ "${1,,}" =~ ^0|no|off|false$ ]] && return 1
    [[ "${1}" ]]
}

ERROR_IS_FATAL=false
INTERUPT_IS_FATAL=true
ERROR_COUNTER=0

HEADER='$(date +"%Y-%m-%d %H-%M-%S") $LEVEL - '

bool "${NOTIFY_RGB_COLORS}" \
    && $(tput colors) -eq 256 \
    || NOTIFY_RGB_COLORS=


# -----------------------------------------------------------------------------
# Notify functions
# -----------------------------------------------------------------------------

notify() {
    local STOP C
    local LEVEL="${1}"; shift
    local DATA="${@}"

    case $LEVEL in
        info)
            C=( "38;2;208;208;208" 37 )
            ;;
        succes)
            C=( "38;2;144;165;126" 32 )
            ;;
        warning)
            C=( "38;2;215;157;101" 33 )
            ;;
        error)
            C=( "38;2;162;102;102" 31 )
            bool "${ERROR_IS_FATAL}" && STOP=true
            ERROR_COUNTER+=1
            ;;
        fatal)
            C=( "38;2;207;0;0" "31;1" )
            ERROR_COUNTER+=1
            STOP=true
            ;;
        *)
            C=( 0 0 )
            DATA="$LEVEL $DATA"
            LEVEL=
            ;;
    esac

    [[ ${NOTIFY_RGB_COLORS} ]] \
        && echo -en "\033[${C[0]}m" >&2 \
        || echo -en "\033[${C[1]}m" >&2

    bool "$HEADER" && echo -en "$(eval echo \"$HEADER\")" >&2

    echo -e "${@}\033[0m" >&2

    bool $STOP && bool "$INTERUPT_IS_FATAL" && exit 1
}

info() {
    [[ ${NOTIFY_RGB_COLORS} ]] && \
        echo -e "\033[38;2;208;208;208m${HEADER}${@}\033[0m" >&2 || \
        echo -e "\033[37m${HEADER}${@}\033[0m" >&2
}

success() {
    [[ ${NOTIFY_RGB_COLORS} ]] && \
        echo -e "\033[38;2;144;165;126m${@}\033[0m" >&2 || \
        echo -e "\033[32m${@}\033[0m" >&2
}

warning() {
    [[ ${NOTIFY_RGB_COLORS} ]] && \
        echo -e "\033[38;2;215;157;101m${@}\033[0m" >&2 || \
        echo -e "\033[33m${@}\033[0m" >&2
}

error() {
    ERROR_COUNTER+=1

    [[ ${NOTIFY_RGB_COLORS} ]] && \
        echo -e "\033[38;2;162;102;102m${@}\033[0m" >&2 || \
        echo -e "\033[31m${@}\033[0m" >&2

    #[[ ${ERROR_IS_FATAL} && ${INTERUPT_IS_FATAL} ]] && exit 1
}

fatal() {
    notify fatal ${@}
    #ERROR_COUNTER+=1

    #[[ ${NOTIFY_RGB_COLORS} ]] && \
        #echo -e "\033[38;2;207;0;0m${@}\033[0m" >&2 || \
        #echo -e "\033[31;1m${@}\033[0m" >&2

    #[[ ${INTERUPT_IS_FATAL} ]] && exit 1
}
