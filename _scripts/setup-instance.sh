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
readonly RepoDir="/tmp/ansible-playbooks"
readonly VirtualEnvDir="/tmp/ansible-venv"

: "${LOG_FILE:="/var/log/user-data.log"}"
: "${DISABLE_OUTPUT_REDIRECT:=""}"

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

    if ! "$@" ; then
        if [[ $exit_on_error -eq 1 ]] ; then
            _msg "Error running command; exiting"
            exit 1
        fi

        _msg "Warning: error running command"
        return 1
    fi
}

check_required_vars()
{
    local -r required_vars=(
        ENVIRONMENT
        INVENTORY
        PLAYBOOK
    )
    local var_name
    local error=0

    _msg "--> Checking environment variables"

    for var_name in "${required_vars[@]}" ; do
        if [[ -z "${!var_name+x}" ]] ; then
            _msg "Error: you must set the ${var_name} environment variable"
            error=1
        fi
    done

    [[ $error -ne 0 ]] && exit 2

    return 0
}

install_deps()
{
    _msg "--> Installing system dependencies"

    _run apt update -q
    _run apt install -q -y --no-install-recommends git make python3 python3-venv
}

clone_repo()
{
    _msg "--> Cloning Git repository"

    if [[ -d "$RepoDir" ]] ; then
        _msg "Repository dir '$RepoDir' already exists; skipping 'git clone'"
        return 0
    fi

    _run git clone --depth 1 "$RepoUrl" "$RepoDir"
}

install_ansible()
{
    _msg "--> Installing Ansible"

    _run make -C "$RepoDir" install-all VENV_DIR="$VirtualEnvDir"

    export PATH="${VirtualEnvDir}/bin:${PATH}"
}

check_required_files()
{
    local file
    local error=0

    _msg "--> Checking required files"

    for file in "$@" ; do
        if [[ ! -f "$file" ]] ; then
            _msg "Error: file '$file' not found"
            error=1
        fi
    done

    return $error
}

run_ansible()
{
    local -r inventory_file="inventories/${ENVIRONMENT}/${INVENTORY}"
    local -r playbook_file="playbooks/${PLAYBOOK}"

    local error_count=0
    local max_retries=2

    (
        _run cd "$RepoDir"

        if ! check_required_files "$inventory_file" "$playbook_file" ; then
            exit 1
        fi

        _msg "--> Running Ansible tasks"

        # Basic commands to help debugging in case of errors
        _run ansible --version
        _run ansible all --connection local --inventory "$inventory_file" -m ping

        # Run the Ansible playbook. Retry up to $max_retries times to be more resilient in case of intermittent errors
        # (e.g. network timeouts)
        while [[ $error_count -le $max_retries ]] ; do
            if _run --no-exit ansible-playbook --connection local --inventory "$inventory_file" "$playbook_file" ; then
                # Command was successful, exit the loop
                break
            fi

            (( error_count++ ))

            _msg "Warning: error running Ansible; retrying (${error_count}/${max_retries})"
            sleep 2
        done
    )

    # shellcheck disable=SC2181
    [[ $? -ne 0 ]] && exit 1
}

do_cleanup()
{
    _msg "--> Cleaning up"

    _run rm -rf "$RepoDir" "$VirtualEnvDir"

    _run apt purge -q -y make

    _msg "Program finished at $( date --utc )"
}

main()
{
    _msg "Starting ${ProgramName} v${ProgramVersion} at $( date --utc )"

    trap do_cleanup EXIT

    check_required_vars

    install_deps
    clone_repo
    install_ansible
    run_ansible

    _msg "Success!"
}


main "$@"
