#!/usr/bin/env bash

LC_ALL=C

bool() {
    [[ "${1,,}" =~ ^0|no|off|false$ ]] && return 1
    [[ "${1}" ]]
}

ERROR_IS_FATAL=false
INTERUPT_IS_FATAL=true
ERROR_COUNTER=0

HEADER='$(date +"%Y-%m-%d %H-%M-%S") $TYPE $LABEL '


# -----------------------------------------------------------------------------
# Notify functions
# -----------------------------------------------------------------------------

notify() {
    local LABEL STOP C
    local TYPE="${1}"; shift
    local DATA="${@}"

    case $TYPE in
        info)
            C='37'
            LABEL='[*]'
            ;;
        succes)
            C='32'
            LABEL='[+]'
            ;;
        warning)
            C='33'
            LABEL='[!]'
            ;;
        error)
            C='31'
            LABEL='[-]'
            ERROR_COUNTER+=1
            bool "${ERROR_IS_FATAL}" && STOP=true
            ;;
        fatal)
            C='31;1'
            LABEL='[-]'
            ERROR_COUNTER+=1
            STOP=true
            ;;
        *)
            DATA="$TYPE $DATA"
            TYPE=
            ;;
    esac

    echo -en "\033[${C:-0}m" >&2
    [[ "$HEADER" ]] && \
        echo -en "$(eval echo \"$HEADER\")" >&2
    echo -e "${@}\033[0m" >&2

    bool $STOP && bool "$INTERUPT_IS_FATAL" && exit 1
}


info()      { notify info    ${@}; }
success()   { notify success ${@}; }
warning()   { notify warning ${@}; }
error()     { notify error   ${@}; }
fatal()     { notify fatal   ${@}; }
