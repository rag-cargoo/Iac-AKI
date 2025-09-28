SHELL := /bin/bash


.DEFAULT_GOAL := run

SETUP_SCRIPT=./run/common/setup_env.sh
CONNECT_SCRIPT=./run/common/connect_service_tunnel.sh
TF_ENV_DIR?=src/iac/terraform/envs/production
ANSIBLE_ENV=ANSIBLE_LOCAL_TMP=/tmp/ansible-local-$(shell whoami) ANSIBLE_REMOTE_TMP=/tmp ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ANSIBLE_PLAYBOOK=src/iac/ansible/playbooks/cluster.yml
ANSIBLE_CFG=src/iac/ansible/ansible.cfg
ANSIBLE_CONFIG_CMD=ANSIBLE_CONFIG=$(CURDIR)/$(ANSIBLE_CFG)

.PHONY: run setup_env ansible clean tunnel tf-init tf-plan tf-apply tf-destroy

# Run full setup + Ansible

ANSIBLE_FORKS ?= 

run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running project environment setup + Ansible..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(ANSIBLE_ENV) $(ANSIBLE_CONFIG_CMD) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(if $(ANSIBLE_FORKS),-f $(ANSIBLE_FORKS),) $(ANSIBLE_PLAYBOOK)"

# Setup environment only
setup_env:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running project environment setup..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@bash -c "source $(SETUP_SCRIPT)"

# Run Ansible playbook only
ansible:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running Ansible playbook..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(ANSIBLE_ENV) $(ANSIBLE_CONFIG_CMD) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(if $(ANSIBLE_FORKS),-f $(ANSIBLE_FORKS),) $(ANSIBLE_PLAYBOOK)"

# Clean
clean:
	@echo "Cleaning temporary files..."
	@rm -f ~/.ssh/config.bak
	@echo "Done."

# SSH tunnel helper
tunnel:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Preparing environment + opening tunnels..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@bash -c "source $(SETUP_SCRIPT) && $(CONNECT_SCRIPT)"

# Terraform helpers (default: production env)
tf-init:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform init ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) init -upgrade

tf-plan:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform plan ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) plan

tf-apply:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform apply ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) apply

tf-destroy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform destroy ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) destroy
