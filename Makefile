SHELL := /bin/bash

.DEFAULT_GOAL := help

LAB01_PREFIX := 01-lab-docker-swarm
LAB01_DIR := labs/$(LAB01_PREFIX)

LAB02_PREFIX := 02-lab-s2svpn
LAB02_DIR := labs/$(LAB02_PREFIX)

ANSIBLE_FLAGS ?= -K

.PHONY: help \
        $(LAB01_PREFIX)-% $(LAB02_PREFIX)-% \
        $(LAB01_PREFIX)-init $(LAB01_PREFIX)-run $(LAB01_PREFIX)-tf-destroy \
        $(LAB01_PREFIX)-tf-plan $(LAB01_PREFIX)-tf-apply \
        $(LAB01_PREFIX)-setup_env $(LAB01_PREFIX)-tunnel \
        $(LAB01_PREFIX)-monitoring_deploy $(LAB01_PREFIX)-monitoring_remove \
        $(LAB01_PREFIX)-jenkins_deploy $(LAB01_PREFIX)-jenkins_remove \
        $(LAB01_PREFIX)-jenkins_password \
        $(LAB02_PREFIX)-init $(LAB02_PREFIX)-tf-plan $(LAB02_PREFIX)-tf-apply $(LAB02_PREFIX)-tf-output $(LAB02_PREFIX)-tf-destroy $(LAB02_PREFIX)-strongswan

help:
	@echo "Available targets:"
	@echo "  make $(LAB01_PREFIX)-init             # Terraform init (one-time)"
	@echo "  make $(LAB01_PREFIX)-run              # Plan → Apply → Ansible"
	@echo "  make $(LAB01_PREFIX)-tf-destroy       # Terraform destroy"
	@echo "  make $(LAB01_PREFIX)-tf-plan          # Terraform plan"
	@echo "  make $(LAB01_PREFIX)-tf-apply         # Terraform apply"
	@echo "  make $(LAB01_PREFIX)-setup_env        # Source setup_env only"
	@echo "  make $(LAB01_PREFIX)-tunnel           # Open service tunnels"
	@echo "  make $(LAB01_PREFIX)-monitoring_deploy # Deploy monitoring stack"
	@echo "  make $(LAB01_PREFIX)-monitoring_remove # Remove monitoring stack"
	@echo "  make $(LAB01_PREFIX)-jenkins_deploy    # Deploy Jenkins stack"
	@echo "  make $(LAB01_PREFIX)-jenkins_remove    # Remove Jenkins stack"
	@echo "  make $(LAB01_PREFIX)-jenkins_password  # Print Jenkins initial admin password"
	@echo "  make $(LAB02_PREFIX)-init             # Terraform init (one-time)"
	@echo "  make $(LAB02_PREFIX)-tf-plan          # Terraform plan"
	@echo "  make $(LAB02_PREFIX)-tf-apply         # Terraform apply"
	@echo "  make $(LAB02_PREFIX)-tf-output        # Terraform output"
	@echo "  make $(LAB02_PREFIX)-tf-destroy       # Terraform destroy"
	@echo "  make $(LAB02_PREFIX)-strongswan       # Install strongSwan locally (Ansible)"

$(LAB01_PREFIX)-init:
	@$(MAKE) -C $(LAB01_DIR) tf-init

$(LAB01_PREFIX)-run:
	@$(MAKE) -C $(LAB01_DIR) workflow

$(LAB01_PREFIX)-tf-destroy:
	@$(MAKE) -C $(LAB01_DIR) destroy

$(LAB01_PREFIX)-tf-plan:
	@$(MAKE) -C $(LAB01_DIR) tf-plan

$(LAB01_PREFIX)-tf-apply:
	@$(MAKE) -C $(LAB01_DIR) tf-apply

$(LAB01_PREFIX)-setup_env:
	@$(MAKE) -C $(LAB01_DIR) setup_env

$(LAB01_PREFIX)-tunnel:
	@$(MAKE) -C $(LAB01_DIR) tunnel

$(LAB01_PREFIX)-monitoring_deploy:
	@$(MAKE) -C $(LAB01_DIR) monitoring_deploy

$(LAB01_PREFIX)-monitoring_remove:
	@$(MAKE) -C $(LAB01_DIR) monitoring_remove

$(LAB01_PREFIX)-jenkins_deploy:
	@$(MAKE) -C $(LAB01_DIR) jenkins_deploy

$(LAB01_PREFIX)-jenkins_remove:
	@$(MAKE) -C $(LAB01_DIR) jenkins_remove

$(LAB01_PREFIX)-jenkins_password:
	@$(MAKE) -C $(LAB01_DIR) jenkins_password

# pattern fallback for any new sub-targets
$(LAB01_PREFIX)-%:
	@$(MAKE) -C $(LAB01_DIR) $*

$(LAB02_PREFIX)-init:
	@$(MAKE) -C $(LAB02_DIR) tf-init

$(LAB02_PREFIX)-tf-plan:
	@$(MAKE) -C $(LAB02_DIR) tf-plan

$(LAB02_PREFIX)-tf-apply:
	@$(MAKE) -C $(LAB02_DIR) tf-apply

$(LAB02_PREFIX)-tf-output:
	@$(MAKE) -C $(LAB02_DIR) tf-output

$(LAB02_PREFIX)-tf-destroy:
	@$(MAKE) -C $(LAB02_DIR) tf-destroy

$(LAB02_PREFIX)-strongswan:
	@ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook labs/$(LAB02_PREFIX)/src/ansible/install_strongswan.yml $(ANSIBLE_FLAGS)

$(LAB02_PREFIX)-%:
	@$(MAKE) -C $(LAB02_DIR) $*
