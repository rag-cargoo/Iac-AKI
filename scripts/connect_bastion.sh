#!/bin/bash

# Script to connect to the bastion host via SSH

set -e

# --- Configuration ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SSH_USER="ubuntu"

# --- Get IPs and Key Path from Environment Variables ---
if [ -z "$BASTION_PUBLIC_IP" ] || [ -z "$SSH_KEY_PATH" ]; then
  echo "Error: Required environment variables (BASTION_PUBLIC_IP, SSH_KEY_PATH) are not set."
  echo "Please source scripts/core_utils/setup_project_env.sh first."
  exit 1
fi

# --- SSH Connection ---
echo "Connecting to bastion host: ${SSH_USER}@${BASTION_PUBLIC_IP}"

ssh -i "${SSH_KEY_PATH}" "${SSH_USER}@${BASTION_PUBLIC_IP}"
