#!/usr/bin/env bash
#
# setup-instance.sh
#
# Bootstrap an EC2 instance using the 'ansible-runner' script in user data mode.
#
##

set -x
set -e
set -o pipefail

: "${REPO_VERSION:="main"}"


main()
{
    curl -m 5 --retry 2 -fL \
        "https://raw.githubusercontent.com/flaudisio/bootcamp-ansible-playbooks/${REPO_VERSION}/roles/local/ansible-runner/files/ansible-runner.sh" \
        -o /tmp/ansible-runner.sh

    bash /tmp/ansible-runner.sh --user-data
}


main "$@"
