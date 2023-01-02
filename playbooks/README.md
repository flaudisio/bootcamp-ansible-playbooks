# Playbooks

This directory contains the playbooks used for provisioning servers and applications.

## Playbook naming system

Playbook filenames **must** use one of the predefined prefixes below.

| Prefix | Description |
|--------|-------------|
| `init-*` | Playbooks that make the node ready to run other playbooks (e.g. by installing the Ansible virtualenv and local repository clone). |
| `adhoc-*` | One-off playbooks that can be used on the CLI or in Semaphore. These are typically for basic tasks. |
| `debug-*` | Playbooks that run debugging tasks. |
| `deploy-*` | Playbooks that provision entire stacks and/or servers. |
| `maint-*` | Playbooks dedicated to maintainance tasks (e.g. system update, etc). |

## Related links

- Inspired by: <https://wiki.rockylinux.org/team/infrastructure/awx_scm_guidelines/#playbook-naming-system>
- See also: <https://github.com/rocky-linux/infrastructure/tree/main/ansible/playbooks>
