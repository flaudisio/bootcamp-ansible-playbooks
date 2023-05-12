#!/usr/bin/env bash
#
# nomad-backups.sh
#
##

# shellcheck disable=SC2174

: "${BACKUP_DIR:="/var/opt/nomad-backups"}"

set -o pipefail

readonly ProgramName="nomad-backups"
readonly ProgramVersion="0.1.0"


_msg()
{
    echo -e "[$( date --utc -Iseconds )] $*" >&2
}

log_info()
{
    _msg "[INFO] $*"
}

log_warn()
{
    _msg "[WARN] $*"
}

log_error()
{
    _msg "[EROR] $*"
}

log_debug()
{
    [[ -n "$DEBUG" ]] && _msg "[DEBG] $*"
}

check_env()
{
    local -r commads=( nomad shuf )
    local cmd
    local error=0

    log_debug "Checking required commands"

    for cmd in "${commads[@]}" ; do
        if ! command -v "$cmd" > /dev/null ; then
            log_error "Command not found: $cmd"
            error=1
        fi
    done

    if [[ $error -ne 0 ]] ; then
        log_error "One or more errors were found; aborting"
        exit 3
    fi
}

create_backup_dir()
{
    log_info "Creating backup directory '$BACKUP_DIR'"

    if ! mkdir -p -m 700 "$BACKUP_DIR" > /dev/null ; then
        log_error "Could not create backup directory; aborting"
        exit 4
    fi
}

create_nomad_snapshot()
{
    local -r snapshot_file="${BACKUP_DIR}/$( date --utc +'%Y%m%d-%H%M%S' ).snap"

    log_info "Running Nomad snapshot command"

    if ! nomad operator snapshot save "$snapshot_file" ; then
        log_error "Could not save Nomad snapshot; aborting"
        exit 1
    fi

    log_info "Snapshot successfully created!"
}

main()
{
    local sleep_secs

    log_info "Running $ProgramName v$ProgramVersion"

    check_env

    if [[ "$1" == "--cron" ]] ; then
        sleep_secs="$( shuf -i 1-20 -n 1 )"

        log_info "Running in cron mode - sleeping for $sleep_secs seconds"
        sleep "$sleep_secs"
    fi

    create_backup_dir
    create_nomad_snapshot

    log_info "Program finished"
}


main "$@"
