#!/bin/bash

is_installed() {
    command -v "$1" >/dev/null 2>&1
}
check_dependency() {
    if ! is_installed "$1"; then
        if declare -f -F log_critical >/dev/null; then
            log_critical "%s is required but it is not installed. Aborting." "$1"
        else
            printf "%s is required but it is not installed. Aborting.\n" "$1"
        fi
        exit 1
    fi
}
check_dependencies() {
    for dep in $@; do
        check_dependency "$dep"
    done
}
