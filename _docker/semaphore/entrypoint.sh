#!/bin/sh
#
# docker-entrypoint.sh
#
##

# shellcheck shell=dash

set -e
set -o pipefail

: "${SSH_LOG_LEVEL:="ERROR"}"


msg()
{
    echo "[entrypoint] $*"
}

fix_directory_permissions()
{
    local data_dir

    for data_dir in \
        "$SEMAPHORE_TMP_PATH" \
        "$SEMAPHORE_CONFIG_PATH" \
        "$SEMAPHORE_DB_PATH"
    do
        if [ ! -d "$data_dir" ] ; then
            msg "[INFO] Creating $data_dir"
            mkdir -p "$data_dir"
        fi

        # Try to create/modify a file using the Semaphore user
        if ! gosu semaphore touch "${data_dir}/.docker-entrypoint-probe" 2> /dev/null ; then
            msg "[INFO] Fixing permissions for $data_dir"

            # Fix directory permissions
            if ! chown -R semaphore "$data_dir" ; then
                msg "[ERROR] Could not fix $data_dir permissions; please check your environment. Aborting Docker entrypoint" >&2
                exit 1
            fi
        fi
    done
}

configure_ssh_client()
{
    msg "[INFO] Configuring SSH client"

    if ! grep -q 'entrypoint.sh' /etc/ssh/ssh_config ; then
        printf "# entrypoint.sh\nHost *\n  LogLevel %s\n" "$SSH_LOG_LEVEL" >> /etc/ssh/ssh_config
        return 0
    fi
}


case $1 in
    semaphore)
        fix_directory_permissions
        configure_ssh_client

        msg "[INFO] Running Semaphore"

        if [ "$2" = "server" ] ; then
            exec gosu semaphore semaphore-wrapper semaphore server --config "${SEMAPHORE_CONFIG_PATH}/config.json"
        fi

        exec gosu semaphore "$@"
    ;;
esac


exec "$@"
