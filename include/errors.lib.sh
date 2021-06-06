

USE_256C=${USE_256C:-true}

if [[ "$USE_256C" ]]; then
    # 256-colors terminal
    CL_NORMAL=${CL_NORMAL:-"38;2;208;208;208"}
    CL_SUCCESS=${CL_SUCCESS:-"38;2;144;165;126"}
    CL_WARNING=${CL_WARNING:-"38;2;215;157;101"}
    CL_ERROR=${CL_ERROR:-"38;2;162;102;102"}
    CL_FATAL=${CL_FATAL:-"38;2;207;0;0"}
fi

CL_NORMAL=${CL_NORMAL:-"37"}
CL_SUCCESS=${CL_SUCCESS:-"32"}
CL_WARNING=${CL_WARNING:-"33"}
CL_ERROR=${CL_ERROR:-"31"}
CL_FATAL=${CL_FATAL:-"31;1"}



normal() {
    echo -e "\033[${CL_NORMAL}m${@}\033[0m" >&2
}

success() {
    echo -e "\033[${CL_SUCCESS}m${@}\033[0m" >&2
}

warning() {
    echo -e "\033[${CL_WARNING}m${@}\033[0m" >&2
}

error() {
    echo -e "\033[${CL_ERROR}m${@}\033[0m" >&2

    [[ ${ERROR_IS_FATAL} ]] && \
        kill $$
}

fatal() {
    echo -e "\033[${CL_FATAL}m${@}\033[0m" >&2
    kill $$ 
}

