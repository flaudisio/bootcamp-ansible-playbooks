COLLECTIONS_PATH := collections
ROLES_PATH := roles/public

VENV_DIR ?= $(HOME)/.virtualenvs/bootcamp-ansible-playbooks

export PATH := $(VENV_DIR)/bin:$(PATH)

IMAGE_REPO ?= flaudisio/bootcamp-semaphore
IMAGE_TAG ?= latest

.PHONY: help
help:  ## Show available commands
	@echo "Available commands:"
	@echo
	@sed -n -E -e 's|^([A-Za-z0-9/_-]+):.+## (.+)|\1@\2|p' $(MAKEFILE_LIST) | column -s '@' -t

.PHONY: lint
lint:  ## Run lint commands
	pre-commit run --all-files --verbose --show-diff-on-failure --color always

.PHONY: install-ansible
install-ansible: REQUIREMENTS ?= _requirements/control-nodes.txt
install-ansible:  ## Install Ansible and dependencies in a virtualenv
	@if [ -n '$(GITLAB_CI)' ] ; then \
		echo "NOTE: GitLab CI environment detected, skipping virtualenv creation." ; \
	elif [ ! -d '$(VENV_DIR)' ] ; then \
		( \
			set -x ; \
			python3 -m venv --clear --upgrade-deps '$(VENV_DIR)' ; \
		) \
	fi
	@[ -d '$(VENV_DIR)' ] && echo "\nVirtualenv is ready on '$(VENV_DIR)' directory!\n" || true
	pip install --upgrade pip -r '$(REQUIREMENTS)'
	@echo
	@echo 'Done! Run "make install-galaxy-deps" to install Galaxy dependencies.'
	@echo

.PHONY: install-galaxy-deps
install-galaxy-deps:  ## Install Galaxy dependencies from requirements.yml
	ansible-galaxy collection install --upgrade --requirements-file collections/requirements.yml --collections-path '$(COLLECTIONS_PATH)'
	@echo
	ansible-galaxy role install --role-file roles/requirements.yml --roles-path '$(ROLES_PATH)'
	@echo
	@echo 'Done! Run "eval $$( make activate )" to use Ansible in the current shell.'
	@echo

.PHONY: install-all
install-all: install-ansible install-galaxy-deps  ## Install Ansible and Galaxy dependencies

.PHONY: activate
activate:  ## Print the virtualenv activation command. Usage: eval $( make activate )
	@echo source $(VENV_DIR)/bin/activate

.PHONY: uninstall
uninstall:  ## Remove the Ansible virtualenv
	rm -rf '$(VENV_DIR)'
	git clean -fdx -- '$(COLLECTIONS_PATH)' '$(ROLES_PATH)'

.PHONY: build-semaphore-image
build-semaphore-image:  ## Build Semaphore Docker image (optional: ARGS)
	docker image build --tag $(IMAGE_REPO):$(IMAGE_TAG) -f _docker/semaphore/Dockerfile . $(ARGS)

.PHONY: push-semaphore-image
push-semaphore-image:  ## Push Semaphore image to Docker Hub
	docker image push $(IMAGE_REPO):$(IMAGE_TAG)
