#!/usr/bin/env bash
[[ ${NOTIFY_LIB_LOADED} ]] && return 0 || NOTIFY_LIB_LOADED=true

LC_ALL=C

bool() {
    [[ "${1,,}" =~ ^0|no|off|false$ ]] && return 1
    [[ "${1}" ]]
}

ERROR_IS_FATAL=false
INTERUPT_IS_FATAL=true

HEADER='$(date +"%Y-%m-%d %H-%M-%S") $TYPE $LABEL'


# -----------------------------------------------------------------------------
# Timer functions
# -----------------------------------------------------------------------------
declare -A TIMERS

set_timer() {
	local name="${1:-default}"
	TIMERS["$name"]=$(date +%s)
}

get_timer() {
	local name="${1:-default}"
	local current=$(date +%s)
	local stored=${TIMERS["$name"]:-$current}
	echo  $(( $current - $stored ))
}

displaytime() {
    local T=$1
    local W=$((T/60/60/24/7))
    local D=$((T/60/60/24%7))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))

    if [[ $W > 0 ]]; then
        printf '%d weeks ' $W
        printf '%d days ' $D
    else
        if [[ $D > 0 ]]; then
            printf '%d days ' $D
            printf '%d hours ' $H
        else
            [[ $H > 0 ]] && printf '%d hours ' $H
            [[ $M > 0 ]] && printf '%d minutes ' $M
            [[ $H = 0 ]] && printf '%d seconds ' $S
        fi
    fi
    echo "ago"
}


# -----------------------------------------------------------------------------
# Notify functions
# -----------------------------------------------------------------------------
ERROR_COUNTER=0

notify() {
    local LABEL STOP C
    local TYPE="${1}"; shift
    local DATA="${@}"

    case $TYPE in
        info)
            C='36'
            LABEL='[*]'
            ;;
        success)
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
            LABEL='[ ]'
            DATA="$TYPE $DATA"
            TYPE=
            ;;
    esac

    echo -en "\r\033[2K\033[${C:-0}m" >&2
    [[ "$HEADER" ]] && \
        echo -en "$(eval echo \"$HEADER \")" >&2
    echo -e "${@}\033[0m" >&2

    if bool $STOP && bool "$INTERUPT_IS_FATAL"; then
		kill -9 $$ >/dev/null 2>&1
		exit 1
	fi

    return 0
}

info()      { notify info    ${@}; }
success()   { notify success ${@}; }
warning()   { notify warning ${@}; }
error()     { notify error   ${@}; }
fatal()     { notify fatal   ${@}; }
