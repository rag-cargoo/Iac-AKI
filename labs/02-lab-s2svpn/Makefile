SHELL := /bin/bash

TF_ENV_DIR ?= $(CURDIR)/src/terraform/envs/production

.DEFAULT_GOAL := tf-plan

.PHONY: tf-init tf-plan tf-apply tf-destroy tf-output

tf-init:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform init ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) init -upgrade

tf-plan:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform plan ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) plan $(PLAN_FLAGS)

tf-apply:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform apply ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) apply $(APPLY_FLAGS)

tf-destroy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔹 Terraform destroy ($(TF_ENV_DIR))"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@terraform -chdir=$(TF_ENV_DIR) destroy $(DESTROY_FLAGS)

tf-output:
	@terraform -chdir=$(TF_ENV_DIR) output
