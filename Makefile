SHELL := /bin/bash


.DEFAULT_GOAL := run

SETUP_SCRIPT=./scripts/core_utils/setup_project_env.sh
ANSIBLE_PLAYBOOK=Iac/ANSIBLE/playbook.yml
DYNAMIC_INVENTORY=./scripts/core_utils/dynamic_inventory.py

.PHONY: run setup_env ansible clean

# Run full setup + Ansible
run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running project environment setup + Ansible..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK) -i $(DYNAMIC_INVENTORY)"

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
	@bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK) -i $(DYNAMIC_INVENTORY)"

# Clean
clean:
	@echo "Cleaning temporary files..."
	@rm -f ~/.ssh/config.bak
	@echo "Done."
