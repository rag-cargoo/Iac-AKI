SHELL := /bin/bash


.DEFAULT_GOAL := run

SETUP_SCRIPT=./scripts/bin/setup_project_env.sh
ANSIBLE_PLAYBOOK=Iac/ANSIBLE/playbooks/cluster.yml
ANSIBLE_CFG=Iac/ANSIBLE/ansible.cfg
ANSIBLE_CONFIG_CMD=ANSIBLE_CONFIG=$(CURDIR)/$(ANSIBLE_CFG)

.PHONY: run setup_env ansible clean

# Run full setup + Ansible
run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running project environment setup + Ansible..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(ANSIBLE_CONFIG_CMD) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK)"

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
	@$(ANSIBLE_CONFIG_CMD) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK)"

# Clean
clean:
	@echo "Cleaning temporary files..."
	@rm -f ~/.ssh/config.bak
	@echo "Done."
