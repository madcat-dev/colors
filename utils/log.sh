#!/usr/bin/env bash
[[ ${NOTIFY_LIB_LOADED} ]] && return 0 || NOTIFY_LIB_LOADED=true

# using as library?
[[ "${0}" != "${BASH_SOURCE}" ]] && \
    NOTIFY_IS_LIB=true || NOTIFY_IS_LIB=

LC_ALL=C

istrue() {
    [[ "${1,,}" =~ ^0|no|n|off|false|f$ ]] && return 1
    [[ "${1}" ]]
}


# Inititalise
[[ ! "${ERROR_IS_FATAL}" ]] \
    && ERROR_IS_FATAL=false

[[ ! "${INTERUPT_IS_FATAL}" ]] \
    && INTERUPT_IS_FATAL=true

[[ ! "${DEBUG_LEVEL}" ]] \
    && DEBUG_LEVEL=1

[[ ! "${ERROR_COUNT_FORMAT}" ]] \
    && ERROR_COUNT_FORMAT="%03d"

[[ ! "${NOTIFY_HEADER}" ]] \
    && NOTIFY_HEADER='$(date +"%Y-%m-%d %H-%M-%S") $ERROR_COUNT ${TYPE} $LABEL'

[[ ! "${LOG_HEADER}" ]] \
    && LOG_HEADER="$NOTIFY_HEADER"

if [[ "${LOG_FILE}" ]]; then
    LOG_DIR="$(dirname "$LOG_FILE")"

    mkdir -p "$LOG_DIR"  2>/dev/null
    touch    "$LOG_FILE" 2>/dev/null

    [[ ! -f "$LOG_FILE" ]] \
        && echo  "ERROR: Log file is not created" \
        && LOG_FILE=
fi

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
    local LEVEL
    local LABEL STOP C PCS ERROR_COUNT
    local TYPE="${1}"; shift
    local DATA="${@}"

    case ${TYPE,,} in
        debug)
            LEVEL=0
            C='36'
            LABEL='[.]'
            ;;
        info)
            LEVEL=1
            C='37'
            LABEL='[i]'
            ;;
        warning)
            LEVEL=2
            C='33'
            LABEL='[!]'
            ;;
        success)
            LEVEL=3
            C='32'
            LABEL='[+]'
            ;;
        error)
            LEVEL=4
            C='31'
            LABEL='[-]'
            ERROR_COUNTER+=1
            istrue "${ERROR_IS_FATAL}" && STOP=true
            ;;
        fatal|critical)
            LEVEL=5
            C='31;1'
            LABEL='[-]'
            ERROR_COUNTER+=1
            STOP=true
            ;;
        *)
            LEVEL=10
            LABEL='[ ]'
            DATA="$TYPE $DATA"
            TYPE=
            ;;
    esac

    ERROR_COUNT=$(printf "$ERROR_COUNT_FORMAT" $ERROR_COUNTER)
    printf -v TYPE "%-8s" ${TYPE^^}

    if [[ $LEVEL -ge $DEBUG_LEVEL ]]; then
        # Std error
        echo -en "\r\033[2K\033[${C:-0}m" >&2

        [[ "$NOTIFY_HEADER" ]] && \
            echo -en "$(eval echo \"$NOTIFY_HEADER \")" >&2

        echo -e "${DATA}\033[0m" >&2

        # File log
        if [[ "${LOG_FILE}" ]]; then
            echo -en "\r\033[2K\033[${C:-0}m" > "${LOG_FILE}"

            [[ "$LOG_HEADER" ]] && \
                echo -en "$(eval echo \"$LOG_HEADER \")" > "${LOG_FILE}"

            echo -e "${DATA}\033[0m" > "${LOG_FILE}"
        fi
    fi

    if istrue $STOP && istrue "$INTERUPT_IS_FATAL"; then
        kill $$ &>/dev/null
        exit 1
	fi

    return 0
}


debug()    { notify debug    ${@}; }
info()     { notify info     ${@}; }
warning()  { notify warning  ${@}; }
error()    { notify error    ${@}; }
fatal()    { notify fatal    ${@}; }
critical() { notify critical ${@}; }
success()  { notify success  ${@}; }


# -----------------------------------------------------------------------------
[[ ${NOTIFY_IS_LIB} ]] && return # run as a library
# -----------------------------------------------------------------------------

notify ${@}

