#!/usr/bin/env bash

_msg()
{
    echo -e "$*" >&2
}

main()
{
    if ! command -v docker > /dev/null ; then
        _msg "Command 'docker' not found; exiting"
        exit 0
    fi

    _msg "Pruning images..."

    if ! docker image prune --all --force ; then
        _msg "Error pruning images; see the script output for details"
        exit 1
    fi

    _msg "Done!"
}

main "$@"
