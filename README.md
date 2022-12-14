# Bootcamp SRE - Ansible Playbooks

Roles e playbooks do Ansible utilizados para provisionar as instâncias do desafio final da Turma 03 do
[Bootcamp de Formação SRE][bootcamp] da ElvenWorks.

[bootcamp]: https://aprenda.elven.works/programas-de-formacao-bootcamp-sre

## Como utilizar

1. Instale o Ansible e dependências do Galaxy:

    ```console
    $ make install-ansible
    $ make install-galaxy-deps
    ```

1. Ative o virtualenv:

    ```console
    $ eval $( make activate )
    $ ansible --version
    ```

1. Configure quaisquer chaves SSH necessárias e execute o Ansible:

    ```console
    $ export ANSIBLE_PRIVATE_KEY_FILE=~/.ssh/example.pem
    $ ansible all -i inventories/example.ini -m ping
    $ ansible-playbook playbooks/example.yml -i inventories/example.ini
    ```

## Limpeza

Para remover o virtualenv do Ansible e quaisquer collections/roles baixadas, execute:

```console
$ make uninstall
```
