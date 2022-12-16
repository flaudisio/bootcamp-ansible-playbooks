#!/usr/bin/env bash
#
# setup-instance.sh
#
# Bootstrap an EC2 instance from its user data using the specified Ansible
# inventory and playbook.
#
##

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

    local retries=0

    if [[ "$1" =~ ^--retry=[0-9]+$ ]] ; then
        retries="${1#*=}"
        shift
    fi

    while true ; do
        # Exit if command is successful
        "$@" && return 0

        if [[ $retries -eq 0 ]] ; then
            _msg "Error running command and no retries left; exiting"
            exit 1
        fi

        _msg "WARNING: error running command. Retries left: $retries"

        (( retries-- ))
        sleep 1
    done
}

check_required_vars()
{
    local -r required_vars=( PLAYBOOK INVENTORY )
    local var_name
    local error=0

    _msg "--> Checking environment variables"

    for var_name in "${required_vars[@]}" ; do
        if [[ -z "${!var_name+x}" ]] ; then
            _msg "Error: you must set the ${var_name} environment variable"
            error=1
        fi
    done

    [[ $error -ne 0 ]] && exit 2 || return 0
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

    _run ansible --version
}

run_ansible()
{
    _msg "--> ${FUNCNAME[0]}"

    if ! (
        _run cd "$RepoDir"

        # Simple ping test to help debugging in case of any problems
        _run ansible all --connection local --inventory "inventories/${INVENTORY}" -m ping

        # Run the machine's playbook
        _run --retry=2 ansible-playbook --connection local --inventory "inventories/${INVENTORY}" "playbooks/${PLAYBOOK}"
    )
    then
        exit 1
    fi
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

    check_required_vars

    install_deps
    clone_repo
    install_ansible
    run_ansible

    do_cleanup

    _msg "Success!"
}


main "$@"
