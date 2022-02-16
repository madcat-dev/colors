#!/usr/bin/env bash
[[ ${ARGS_LIB_LOADED} ]] && return 0 || ARGS_LIB_LOADED=true

LC_ALL=C

source "$(dirname "${0/\~/$HOME}")/estimate.sh"
