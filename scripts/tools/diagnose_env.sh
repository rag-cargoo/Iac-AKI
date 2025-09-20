#!/bin/bash

# Comprehensive diagnostic script to check environment, Terraform outputs, and dynamic inventory.

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)
TERRAFORM_ENVIRONMENT=${TERRAFORM_ENVIRONMENT:-production}
export TERRAFORM_ENVIRONMENT
ENV_DIR="$PROJECT_ROOT/Iac/TERRAFORM/envs/$TERRAFORM_ENVIRONMENT"

echo "--- Running setup_project_env.sh ---"
source "$PROJECT_ROOT/scripts/bin/setup_project_env.sh"
echo "--- setup_project_env.sh finished ---"
echo ""

echo "--- Environment Variables after setup_project_env.sh ---"
echo "BASTION_PUBLIC_IP: $BASTION_PUBLIC_IP"
echo "MANAGER_PRIVATE_IP: $MANAGER_PRIVATE_IP"
echo "WORKER_PRIVATE_IPS: $WORKER_PRIVATE_IPS"
echo "SSH_KEY_PATH: $SSH_KEY_PATH"
echo "--- End of Environment Variables ---"
echo ""

echo "--- Raw Terraform Outputs (JSON) ---"
terraform -chdir="$ENV_DIR" output -json
echo "--- End of Raw Terraform Outputs ---"
echo ""

echo "--- Dynamic Inventory Script Output ---"
ANSIBLE_INVENTORY_PLUGIN="$PROJECT_ROOT/Iac/ANSIBLE/inventory_plugins/swarm.py"
python3 "$ANSIBLE_INVENTORY_PLUGIN"
echo "--- End of Dynamic Inventory Script Output ---"
echo ""

echo "--- Diagnostic Complete ---"
