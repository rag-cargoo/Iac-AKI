#!/bin/bash

# Script to connect directly to the Swarm Manager node via the Bastion host.
# This script automates fetching the bastion IP, handling the ssh-agent, and SSH agent forwarding.

set -e

# Source the project environment setup script to get Terraform outputs and SSH key path
source "$(dirname "$0")/core_utils/setup_project_env.sh"

# --- Configuration ---
# Get the absolute path to the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

TERRAFORM_DIR="${SCRIPT_DIR}/../Iac/TERRAFORM"
MANAGER_HOST="$MANAGER_PRIVATE_IP" # Now comes from environment variable
SSH_USER="ubuntu"
KEY_PATH="$SSH_KEY_PATH" # Now comes from environment variable
BASTION_PUBLIC_IP="$BASTION_PUBLIC_IP" # Now comes from environment variable

# --- SSH Agent --- 
# This part is now handled by setup_project_env.sh

# --- SSH Connection ---
# If a command is provided as an argument, execute it on the manager.
# Otherwise, provide an interactive shell.
if [ -n "$1" ]; then
  echo "Executing command on Swarm Manager ($MANAGER_HOST) via Bastion ($BASTION_PUBLIC_IP)..."
  ssh -A -t "${SSH_USER}@${BASTION_PUBLIC_IP}" ssh -t "${SSH_USER}@${MANAGER_HOST}" "$@"
else
  echo "Connecting to Swarm Manager ($MANAGER_HOST) via Bastion ($BASTION_PUBLIC_IP)..."
  ssh -A -t "${SSH_USER}@${BASTION_PUBLIC_IP}" ssh -t "${SSH_USER}@${MANAGER_HOST}"
fi