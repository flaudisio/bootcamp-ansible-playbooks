#!/usr/bin/env bash
#
# ansible-run.sh
#
# Bootstrap and/or configure an EC2 instance using a specified service and
# (optionally) role.
#
##

set -o pipefail

readonly ProgramName="ansible-run"
readonly ProgramVersion="0.1.0"

readonly RepoUrl="https://github.com/flaudisio/bootcamp-ansible-playbooks.git"
readonly RepoDir="/opt/ansible-playbooks"
readonly AnsibleVenvDir="/opt/ansible-control"

readonly ConfigFile="/etc/ansible-run.conf"
readonly LogFile="/var/log/ansible-run.log"

# Initialize environment variables
: "${EXTRA_VARS:=""}"
: "${REPO_VERSION:="main"}"
: "${USER_DATA_MODE:=""}"
: "${DISABLE_OUTPUT_REDIRECT:=""}"


_msg()
{
    echo -e "$*" >&2
}

_is_user_data()
{
    [[ -n "$USER_DATA_MODE" ]]
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
    local -r max_retries=2
    local retry_count=0

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

setup_logging()
{
    [[ -n "$DISABLE_OUTPUT_REDIRECT" ]] && return 0

    # Send the log output from this script to log file, syslog, and the console
    # Ref: https://alestic.com/2010/12/ec2-user-data-output/
    exec > >( tee -a "$LogFile" | logger -t "$ProgramName" -s 2> /dev/console) 2>&1
    echo "Notice: redirecting all script output to $LogFile" >&2
}

load_config()
{
    # Config is not required in user data mode
    _is_user_data && return 0

    # shellcheck disable=SC1090
    if ! source "$ConfigFile" ; then
        _msg "Error: could not read config file '$ConfigFile'; aborting"
        exit 1
    fi
}

check_required_vars()
{
    local -r required_vars=( ENVIRONMENT SERVICE )
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

    # Use service name for the role when it's not defined
    [[ -z "$ROLE" ]] && ROLE="$SERVICE"

    return 0
}

install_system_deps()
{
    # Only required in user data mode
    _is_user_data || return 0

    _msg "--> Installing system dependencies"

    DEBIAN_FRONTEND=noninteractive _run apt update -q
    DEBIAN_FRONTEND=noninteractive _run apt install -q -y --no-install-recommends python3 python3-venv git make
}

update_playbooks_repo()
{
    local -r remote_branch="origin/$REPO_VERSION"
    local -r status_file="/var/tmp/${ProgramName}.checksum"
    local saved_commit
    local head_commit

    if [[ ! -d "$RepoDir" ]] ; then
        _msg "--> Cloning Playbooks repository"

        _run git clone --quiet "$RepoUrl" "$RepoDir"
        _run git -C "$RepoDir" checkout "$REPO_VERSION"

        return 0
    fi

    _msg "--> Updating refs"

    _run git -C "$RepoDir" fetch --all --prune --quiet

    saved_commit="$( cat "$status_file" 2> /dev/null )"
    head_commit="$( git -C "$RepoDir" rev-parse "$remote_branch" 2> /dev/null )"

    _msg "--> Checking current commit"

    if [[ "$saved_commit" == "$head_commit" ]] ; then
        _msg "--> The saved commit is the current commit on HEAD ($REPO_VERSION); no need to update the repository"
        return 0
    fi

    _msg "--> Updating repository"

    _run git -C "$RepoDir" checkout --force "$REPO_VERSION"
    _run git -C "$RepoDir" reset --hard "$remote_branch"

    _msg "--> Repository updated!"

    _msg "--> Saving current repo commit"

    echo "$head_commit" > "$status_file"
}

update_ansible()
{
    _msg "--> Installing/updating Ansible and playbook dependencies"

    _run_with_retry make -C "$RepoDir" install-all VENV_DIR="$AnsibleVenvDir"

    # NOTE: the venv dir must be added to the *end* of PATH so the Python binaries
    # in the control and managed virtualenvs are NOT symlinked to the venv binary
    _run export PATH="${PATH}:${AnsibleVenvDir}/bin"
}

run_ansible_playbooks()
{
    local -r inventory_file="inventories/${ENVIRONMENT}/${SERVICE}.aws_ec2.yml"
    local -r playbook_file="playbooks/role-${ROLE}.yml"

    _msg "--> Getting instance IP"

    local -r instance_ip="$( _run curl -m 1 --retry 2 -fsSL http://169.254.169.254/latest/meta-data/local-ipv4 )"

    _msg "--> Parsing defined extra vars"

    local extra_vars=()

    mapfile -t extra_vars < <( tr ',' '\n' <<< "$EXTRA_VARS" )

    _msg "--> Setting Ansible command options"

    local ansible_opts=( --connection "local" --inventory "$inventory_file" --limit "$instance_ip" )
    local var

    for var in "${extra_vars[@]}" ; do
        ansible_opts+=( -e "$var" )
    done

    _run pushd "$RepoDir"

    _msg "--> Checking if inventory and playbook files exist"

    _check_files_exist "$inventory_file" "$playbook_file" || exit 1

    # Output Ansible version to help on troubleshooting
    _run ansible --version

    if _is_user_data ; then
        _msg "--> Running initialization playbooks"

        _run_with_retry ansible-playbook playbooks/init-ansible-venv.yml --verbose "${ansible_opts[@]}"
    fi

    _msg "--> Running node playbooks"

    _run_with_retry ansible-playbook "$playbook_file" "${ansible_opts[@]}"

    _run popd

    _msg "--> Ansible playbooks successfully run!"
}

save_config()
{
    # Only required in user data mode
    _is_user_data || return 0

    _msg "--> Saving config file"

    cat <<EOF > "$ConfigFile"
ENVIRONMENT="${ENVIRONMENT}"
SERVICE="${SERVICE}"
ROLE="${ROLE}"
EOF
}

main()
{
    _msg "Starting ${ProgramName} v${ProgramVersion} at $( date --utc )"

    [[ "$1" == "--user-data" ]] && USER_DATA_MODE="1"

    _is_user_data && _msg "--> Note: running in user data mode"

    load_config
    check_required_vars
    install_system_deps
    update_playbooks_repo
    update_ansible
    run_ansible_playbooks
    save_config

    _msg "Program finished at $( date --utc )"
}

# Start logging as soon as possible
setup_logging

main "$@"
