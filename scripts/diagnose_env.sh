#!/bin/bash

# Comprehensive diagnostic script to check environment, Terraform outputs, and dynamic inventory.

set -e

echo "--- Running setup_project_env.sh ---"
source scripts/core_utils/setup_project_env.sh
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
terraform -chdir=Iac/TERRAFORM output -json
echo "--- End of Raw Terraform Outputs ---"
echo ""

echo "--- Dynamic Inventory Script Output ---"
python3 scripts/core_utils/dynamic_inventory.py
echo "--- End of Dynamic Inventory Script Output ---"
echo ""

echo "--- Diagnostic Complete ---"
