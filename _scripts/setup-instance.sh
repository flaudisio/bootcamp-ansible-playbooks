#!/usr/bin/env bash
#
# setup-instance.sh
#
# Bootstrap an EC2 instance from its user data using the specified Ansible
# inventory and playbook.
#
##

set -o pipefail

readonly ProgramName="setup-instance"
readonly ProgramVersion="0.1.0"

readonly RepoUrl="https://github.com/flaudisio/bootcamp-sre-ansible-playbooks.git"
readonly TempPlaybooksDir="/tmp/ansible-playbooks"
readonly AnsibleVenvDir="/opt/ansible-control"

: "${REPO_BRANCH:="main"}"
: "${LOG_FILE:="/var/log/user-data.log"}"
: "${DISABLE_OUTPUT_REDIRECT:=""}"
: "${DISABLE_CLEANUP:=""}"

# Start logging to file as soon as possible
if [[ -z "$DISABLE_OUTPUT_REDIRECT" ]] ; then
    # Ref: https://stackoverflow.com/a/314678/5463829
    exec > >( tee -a "$LOG_FILE" ) 2>&1
    echo "Notice: redirecting all script output to $LOG_FILE" >&2
fi


_msg()
{
    echo -e "$*" >&2
}

_run()
{
    _msg "+ $*"

    local exit_on_error=1

    if [[ "$1" == "--no-exit" ]] ; then
        exit_on_error=0
        shift
    fi

    "$@" && return 0

    if [[ $exit_on_error -eq 1 ]] ; then
        _msg "Error running command; exiting"
        exit 1
    fi

    _msg "Warning: error running command"
    return 1
}

_run_with_retry()
{
    local retry_count=0
    local max_retries=2

    # Retry up to $max_retries times to be more resilient in case of intermittent errors (e.g. network timeouts)
    while [[ $retry_count -le $max_retries ]] ; do
        if _run --no-exit "$@" ; then
            # Command was successful, exit function
            return 0
        fi

        (( retry_count++ ))

        _msg "Warning: error running command; retrying (${retry_count}/${max_retries})"
        sleep 2
    done

    _msg "Unrecoverable error running command; exiting"
    exit 1
}

_check_files_exist()
{
    local file
    local error=0

    for file in "$@" ; do
        if [[ ! -f "$file" ]] ; then
            _msg "Error: file '$file' not found"
            error=1
        fi
    done

    return $error
}

check_required_vars()
{
    local -r required_vars=( ENVIRONMENT INVENTORY PLAYBOOK )
    local var_name
    local error=0

    _msg "--> Checking required environment variables"

    for var_name in "${required_vars[@]}" ; do
        if [[ -z "${!var_name+x}" ]] ; then
            _msg "Error: you must set the ${var_name} environment variable"
            error=1
        fi
    done

    [[ $error -ne 0 ]] && exit 2

    return 0
}

install_system_deps()
{
    _msg "--> Installing system dependencies"

    DEBIAN_FRONTEND=noninteractive _run apt update -q
    DEBIAN_FRONTEND=noninteractive _run apt install -q -y --no-install-recommends git make python3 python3-venv
}

install_ansible()
{
    _msg "--> Cloning playbooks repository to temp dir"

    _run rm -rf "$TempPlaybooksDir"
    _run git clone --branch "$REPO_BRANCH" --depth 1 "$RepoUrl" "$TempPlaybooksDir"

    _msg "--> Installing Ansible"

    _run_with_retry make -C "$TempPlaybooksDir" install-all VENV_DIR="$AnsibleVenvDir"

    export PATH="${AnsibleVenvDir}/bin:${PATH}"
}

run_ansible_playbooks()
{
    local -r inventory_file="inventories/${ENVIRONMENT}/${INVENTORY}"
    local -r playbook_file="playbooks/${PLAYBOOK}"
    local -r ansible_opts=( --connection "local" --inventory "$inventory_file" )

    _run pushd "$TempPlaybooksDir"

    _msg "--> Checking if inventory and playbook files exist"

    _check_files_exist "$inventory_file" "$playbook_file" || exit 1

    # Output Ansible version to help on troubleshooting
    _run ansible --version

    _msg "--> Running initialization tasks"

    _run_with_retry ansible-playbook playbooks/init-ansible-venv.yml --verbose "${ansible_opts[@]}"

    _msg "--> Running node role tasks"

    _run_with_retry ansible-playbook "$playbook_file" "${ansible_opts[@]}"

    _run popd
}

do_cleanup()
{
    if [[ -n "$DISABLE_CLEANUP" ]] ; then
        _msg "Notice: DISABLE_CLEANUP variable set; skipping cleanup"
    else
        _msg "--> Cleaning up"

        _run rm -rf "$TempPlaybooksDir"

        DEBIAN_FRONTEND=noninteractive _run apt purge -q -y make
    fi

    _msg "Program finished at $( date --utc )"
}

main()
{
    _msg "Starting ${ProgramName} v${ProgramVersion} at $( date --utc )"

    trap do_cleanup EXIT

    check_required_vars
    install_system_deps
    install_ansible
    run_ansible_playbooks

    _msg "Success!"
}


main "$@"
