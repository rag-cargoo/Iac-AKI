SHELL := /bin/bash

LAB_ROOT := $(CURDIR)

SETUP_SCRIPT := $(LAB_ROOT)/src/run/common/setup_env.sh
CONNECT_SCRIPT := $(LAB_ROOT)/src/run/common/connect_service_tunnel.sh
TF_ENV_DIR ?= $(LAB_ROOT)/src/terraform/envs/production
SETUP_ENV_FORCE ?=
ANSIBLE_ENV := ANSIBLE_LOCAL_TMP=/tmp/ansible-local-$(shell whoami) ANSIBLE_REMOTE_TMP=/tmp ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ANSIBLE_PLAYBOOK := $(LAB_ROOT)/src/ansible/playbooks/cluster.yml
ANSIBLE_CONFIG_PATH := $(LAB_ROOT)/src/ansible/ansible.cfg
ANSIBLE_FORKS ?=

.DEFAULT_GOAL := run

.PHONY: run setup_env setup_env_refresh ansible clean tunnel \
        tf-init tf-plan tf-apply tf-destroy \
        monitoring_deploy monitoring_remove \
        jenkins_deploy jenkins_remove jenkins_password \
        diagnose workflow destroy

run:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running lab environment setup + Ansible..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@SETUP_ENV_FORCE=$(SETUP_ENV_FORCE) $(ANSIBLE_ENV) ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_PATH) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(if $(ANSIBLE_FORKS),-f $(ANSIBLE_FORKS),) $(ANSIBLE_PLAYBOOK)"

workflow:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform plan → apply → Ansible run"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(MAKE) tf-plan
	@$(MAKE) tf-apply
	@$(MAKE) run

setup_env:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running lab environment setup..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@SETUP_ENV_FORCE=$(SETUP_ENV_FORCE) bash -c "source $(SETUP_SCRIPT)"

setup_env_refresh:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Refreshing lab environment setup..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@SETUP_ENV_FORCE=1 bash -c "source $(SETUP_SCRIPT)"

ansible:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running Ansible playbook..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@SETUP_ENV_FORCE=$(SETUP_ENV_FORCE) $(ANSIBLE_ENV) ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_PATH) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(if $(ANSIBLE_FORKS),-f $(ANSIBLE_FORKS),) $(ANSIBLE_PLAYBOOK)"

clean:
	@echo "Cleaning cached environment files..."
	@rm -f $(LAB_ROOT)/src/run/common/.setup_env_cache
	@echo "Done."

tunnel:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Preparing environment + opening tunnels..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@SETUP_ENV_FORCE=$(SETUP_ENV_FORCE) bash -c "source $(SETUP_SCRIPT) && $(CONNECT_SCRIPT)"

monitoring_deploy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Deploying monitoring stack (Prometheus + Grafana + Node Exporter)..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@docker network create --driver overlay monitoring_net >/dev/null 2>&1 || true
	@docker stack deploy -c $(LAB_ROOT)/src/run/stacks/monitoring/stack.yml monitoring

monitoring_remove:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Removing monitoring stack..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@docker stack rm monitoring

jenkins_deploy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Deploying Jenkins stack (CI/CD)..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@docker stack deploy -c $(LAB_ROOT)/src/run/stacks/ci_cd/jenkins/stack.yml jenkins

jenkins_remove:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Removing Jenkins stack..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@docker stack rm jenkins

jenkins_password:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Fetching Jenkins initial admin password..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@docker ps --filter name=jenkins_jenkins --format '{{.ID}}' | head -n1 | \
		xargs -I{} docker exec {} cat /var/jenkins_home/secrets/initialAdminPassword

destroy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform destroy"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(MAKE) tf-destroy

diagnose:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Running environment diagnostics..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@TERRAFORM_ENVIRONMENT=$(notdir $(TF_ENV_DIR)) bash $(LAB_ROOT)/src/run/common/diagnose_env.sh

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
