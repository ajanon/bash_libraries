#!/bin/bash    

temp_dir() {
    local -r dirpath="$(mktemp -d)"
    if [[ ! "$dirpath" || ! -d "$dirpath" ]]; then
        if declare -f -F log_error >/dev/null; then
            log_error "Could not create temporary directory."
        else
            printf "Could not create temporary directory.\n"
        fi
        return 1
    fi
    declare -f -F log_debug >/dev/null \
        && log_debug "Created temp dir %s" "$dirpath"
    if [[ -z ${__TEMP_DIR_LIST__+x} ]]; then
        declare -ag __TEMP_DIR_LIST__=("$dirpath")
        trap temp_dir_cleanup EXIT
    else
        __TEMP_DIR_LIST__+=("$dirpath")
    fi
    echo "${dirpath}"
}

temp_dir_cleanup() {
    for dirpath in "${__TEMP_DIR_LIST__[@]}"; do
        if ! rm -rf "$dirpath"; then
            if declare -f -F log_critical >/dev/null; then
                log_critical "Could not delete directory %s. Aborting." "$dirpath"
            else
                printf "Could not delete directory %s. Aborting.\n" "$dirpath"
            fi
        else
            if declare -f -F log_debug >/dev/null; then
                log_debug "Deleted temp dir %s" "$dirpath"
            fi
        fi
    done
}
