# Playbooks

This directory contains the playbooks used for provisioning servers and applications.

## Playbook naming system

Playbook filenames **must** use one of the predefined prefixes below.

| Prefix | Description |
|--------|-------------|
| `init-*` | Playbooks that make a node ready to run other playbooks (e.g. by installing the Ansible virtualenv and local repository clone). |
| `adhoc-*` | One-off playbooks that can be used on the CLI or in Semaphore. These are typically for basic tasks. |
| `maint-*` | Playbooks for maintainance tasks (e.g. system updates). |
| `debug-*` | Playbooks for debugging tasks (e.g. variable dumping). |
| `svc-*` | Playbooks for provisioning services. |

## Related links

- Inspired by: <https://wiki.rockylinux.org/team/infrastructure/awx_scm_guidelines/#playbook-naming-system>
- See also: <https://github.com/rocky-linux/infrastructure/tree/main/ansible/playbooks>
