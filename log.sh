#!/bin/bash
#
# Logging library
# It is designed to write all logs to $logfile. This variable must be provided
#+and the file created beforehand. Please note that all ANSI escape sequences
#+will be stripped before writing to the file.
# This library is controlled by a verbosity variable. Messages below the current
#+verbosity level will be output to STDERR. Please note that _all_ messages
#+are output to the log file, even on the lowest verbosity level.
# All log functions (with the exception of log_wrapper) have the same
#+capabilities and syntax as the printf builtin.
# The general format for all logs is:
# [timestamp] {script name} formatted message
# Alternatively, for log_(level) functions, the name of the level will be added:
# [timestamp] {script_name} colored level name: formatted message
# The default timestamp is iso-8601 formatted, up to nanosecond precision,
# for utc.

####################
# init_logging
#   Initializes global constants and variables for logging
# Globals:
#   __LOG__: if set, the logging library has already been initialized
#   DATE_OPTIONS
#   SILENT_LVL
#   CRIT_LVL
#   ERR_LVL
#   WARN_LVL
#   INFO_LVL
#   DEBUG_LVL
#   C_RESET
#   C_DEFAULT
#   C_BLACK
#   C_RED
#   C_GREEN
#   C_YELLOW
#   C_BLUE
#   C_MAGENTA
#   C_CYAN
#   C_LGRAY
# Arguments:
#   None
# Returns:
#   Nothing
####################
init_logging() {
    declare -gr __LOG__=""

    # date options
    # Controls the timestamp formatting.
    # Default: utc with iso-8601 formatting up to nanosecond precision.
    declare -gra __LOG_DATE_OPTIONS_FILE__=("--utc" "--rfc-3339=ns")
    declare -gra __LOG_DATE_OPTIONS_TTY__=("+%F %T")

    ####################
    # Verbosity constants
    # SILENT    completely silences the output
    # CRITICAL  for non-recoverable errors: the calling script should abort after
    # ERROR     recoverable errors
    # WARNING   warnings
    # INFO      informational logs
    # DEBUG     debug or trace-level logs, usually best suited to the log file
    ####################
    declare -gri SILENT_LVL=0
    declare -gri CRIT_LVL=1
    declare -gri ERR_LVL=2
    declare -gri WARN_LVL=3
    declare -gri INFO_LVL=4
    declare -gri DEBUG_LVL=5

    # Verbosity level
    # Controls which messages will be shown
    # Every message is still output to the log file, even on SILENT mode.
    # To avoid writing to the log file, 
    # Default: CRITICAL only.
    declare -gi verbosity=$CRIT_LVL

    ####################
    # Common ANSI escape sequences
    ####################
    declare -gr C_RESET="\e[0m"
    declare -gr C_DEFAULT="\e[39m"
    declare -gr C_BLACK="\e[30m"
    declare -gr C_RED="\e[31m"
    declare -gr C_GREEN="\e[32m"
    declare -gr C_YELLOW="\e[33m"
    declare -gr C_BLUE="\e[34m"
    declare -gr C_MAGENTA="\e[35m"
    declare -gr C_CYAN="\e[36m"
    declare -gr C_LGRAY="\e[37m"
}

####################
# log_wrapper
#   Wrapper for the various logging functions. Should not be called directly.
#   It outputs all logs (regardless of verbosity) to the file path specified in
#+  logfile. The file must exist and be writable.
#   The log has the following format:
#     [timestamp] {script name} formatted message
#   Alternatively, if level_name is specified:
#     [timestamp] {script_name} colored level name: formatted message
# 
# Globals:
#   verbosity: current verbosity value
#   logfile: path to the logfile (ideally an absolute path)
#   C_RESET: to reset the terminal colors
#   DATE_OPTIONS: controls the timestamp format
# Arguments
#   level: verbosity must be greater than this value for the message to be shown
#   level_name: name of the current level. If this is an empty string,
#+              the format is:
#               [timestamp] {script_name} formatted message
#   color: the color for level_name. It is not used if level_name is empty
#   fmt: the format string, as for the printf builtin
#   $@: all following arguments are used, as with the printf builtin
# Returns:
#   Nothing
####################
log_wrapper() {
    local level="$1"
    local level_name="$2"
    local color="$3"
    local fmt="$4"
    shift 4
    local -r script_name="$(basename ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]})"
    local -r timestamp="$(date +'%s.%N')"
    local -r timestamp_file="$(date -d@$timestamp "${__LOG_DATE_OPTIONS_FILE__[@]}")"
    local -r timestamp_tty="$(date -d@$timestamp "${__LOG_DATE_OPTIONS_TTY__[@]}")"
    if [[ -n "$level_name" ]]; then
        [[ -w "${logfile:-}" ]] && printf "[%s] %-10s: ${fmt}\n" "$timestamp_file" "$level_name" "$@" | sed 's/\x1b\[[0-9;]*[mGKH]//g' >> "$logfile"
        if [[ $verbosity -ge $level ]]; then
            printf "[%s] {%s} ${color}%-10s${C_RESET}: ${fmt}\n" "$timestamp_tty" "$script_name" "$level_name" "$@" >&2
        fi
    else
        [[ -w "${logfile:-}" ]] && printf "[%s] ${fmt}\n" "$timestamp_file" "$@" | sed 's/\x1b\[[0-9;]*[mGKH]//g' >> "$logfile"
        if [[ $verbosity -ge $level ]]; then
            printf "[%s] {%s} ${fmt}\n" "$timestamp_tty" "$script_name" "$@" >&2
        fi
    fi
}

####################
# log
#   Outputs a log in the default color. The format is the same as log_wrapper.
#   This does not output any level name.
#   This function is intended to be used for quick logging.
#   It has the same capabilities as printf.
# Globals:
#   verbosity
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log() {
    log_wrapper "$verbosity" "" "$C_LGRAY" "$@"
}

####################
# log_critical
#   Outputs a critical log in magenta. The format is the same as log_wrapper,
#+  with level_name=CRITICAL.
#   This should only be used for non-recoverable errors. For recoverable errors,
#+  see log_error.
# Globals:
#   CRIT_LVL
#   C_MAGENTA
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log_critical() {
    log_wrapper "$CRIT_LVL" "CRITICAL" "$C_MAGENTA" "$@"
}

####################
# log_error
#   Outputs an error log in red. The format is the same as log_wrapper,
#+  with level_name=ERROR.
#   This should only be used for recoverable errors. For non-recoverable errors,
#+  see log_critical.
# Globals:
#   ERR_LVL
#   C_RED
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log_error() {
    log_wrapper "$ERR_LVL" "ERROR" "$C_RED" "$@"
}

####################
# log_warn
#   Outputs a warning log in yellow. The format is the same as log_wrapper,
#+  with level_name=WARNING.
#   This should only be used for warnings. For errors, see log_error and
#+  log_critical.
# Globals:
#   WARN_LVL
#   C_YELLOW
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log_warn() {
    log_wrapper "$WARN_LVL" "WARNING" "$C_YELLOW" "$@"
}

####################
# log_info
#   Outputs an informational log in blue. The format is the same as log_wrapper,
#+  with level_name=INFO.
#   This should only be used for informational messages destined to the end
#+  user. For debug or trace-level messages, see log_debug.
# Globals:
#   INFO_LVL
#   C_BLUE
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log_info() {
    log_wrapper "$INFO_LVL" "INFO" "$C_BLUE" "$@"
}

####################
# log_info
#   Outputs a debug or trace-level log in the default color. The format is the
#+  same as log_wrapper, with level_name=DEBUG.
#   This should only be used for debugging or trace messages for development
#+  purposes.
# Globals:
#   DEBUG_LVL
#   C_DEFAULT
# Arguments:
#   same as printf
# Returns:
#   Nothing
####################
log_debug() {
    log_wrapper "$DEBUG_LVL" "DEBUG" "$C_DEFAULT" "$@"
}

{ [[ -z ${__LOG__+x} ]] && init_logging; } || true
