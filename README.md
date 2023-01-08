# Bootcamp SRE - Ansible Playbooks

Roles e playbooks do Ansible utilizados para provisionar as instâncias do desafio final da Turma 03 do
[Bootcamp de Formação SRE][bootcamp] da ElvenWorks.

[bootcamp]: https://aprenda.elven.works/programas-de-formacao-bootcamp-sre

## Como utilizar

1. Clone o repositório:

    ```console
    $ git clone https://github.com/flaudisio/bootcamp-sre-ansible-playbooks.git
    $ cd bootcamp-sre-ansible-playbooks/
    ```

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

## Provisionando novos servidores

### Via user data

Utilize o script `setup-instance.sh` no user data da instância. Exemplo:

```sh
#!/bin/bash

export ENVIRONMENT="development"
export INVENTORY="wireguard.ini"
export PLAYBOOK="deploy-wireguard.yml"

curl -m 5 --retry 2 -fL "https://raw.githubusercontent.com/flaudisio/bootcamp-sre-ansible-playbooks/main/_scripts/setup-instance.sh" | bash
```

### Via Ansible (máquina local)

Para provisionar uma instância que não foi inicializada via user data, utilize o playbook de inicialização seguido pelo
playbook relativo à instância.

Exemplo:

```console
$ ansible-playbook -i inventories/development/wireguard.ini playbooks/init-ansible-venv.yml
$ ansible-playbook -i inventories/development/wireguard.ini playbooks/deploy-wireguard.yml
```
