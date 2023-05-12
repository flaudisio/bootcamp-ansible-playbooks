# Installation requirements

This directory contains [pip requirements](https://pip.pypa.io/en/stable/reference/requirements-file-format/) for installing
the required dependencies for running Ansible on hosts. The following files are used:

- [`control-nodes.txt`](./control-nodes.txt): dependencies for Ansible [control nodes](https://docs.ansible.com/ansible/latest/getting_started/basic_concepts.html#control-node),
  i.e. the hosts that _run_ the `ansible-playbook` command.

- [`managed-nodes.txt`](./managed-nodes.txt): dependencies for Ansible [managed nodes](https://docs.ansible.com/ansible/latest/getting_started/basic_concepts.html#managed-nodes),
  i.e. the hosts that are _affected by_ the `ansible-playbook` command.

For installation instructions, see the [repository README](../README.md).
