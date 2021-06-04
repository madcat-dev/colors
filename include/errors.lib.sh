

normal() {
    echo -e "\033[37m${@}\033[0m" >&2
}

success() {
    echo -e "\033[32m${@}\033[0m" >&2
}

warning() {
    echo -e "\033[33m${@}\033[0m" >&2
}

error() {
    echo -e "\033[31m${@}\033[0m" >&2

    [[ ${ERROR_IS_FATAL} ]] && \
        kill $$
}

fatal() {
    echo -e "\033[31m${@}\033[0m" >&2
    kill $$ 
}

