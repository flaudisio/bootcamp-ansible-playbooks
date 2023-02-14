#!/usr/bin/env bash
#
# setup-instance.sh
#
# Bootstrap an EC2 instance from its user data using the specified Ansible
# inventory and playbook.
#
##

set -x
set -e
set -o pipefail

: "${PLAYBOOKS_REPO_VERSION:="main"}"
export PLAYBOOKS_REPO_VERSION


main()
{
    curl -m 5 --retry 2 -fL \
        "https://raw.githubusercontent.com/flaudisio/bootcamp-ansible-playbooks/${PLAYBOOKS_REPO_VERSION}/roles/local/ansible-run/files/ansible-run.sh" \
        -o /tmp/ansible-run.sh

    bash /tmp/ansible-run.sh --user-data
}


main "$@"
