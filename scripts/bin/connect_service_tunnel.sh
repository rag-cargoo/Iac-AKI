#!/bin/bash

# Generic script to establish an SSH tunnel to any service via the bastion host.

set -e

# Source the project environment setup script to get Terraform outputs and SSH key path
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}/setup_project_env.sh"

# --- Configuration ---
# Determine project root and terraform directory
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)
TERRAFORM_DIR="$PROJECT_ROOT/infra/terraform"

SSH_KEY_PATH="$SSH_KEY_PATH" # Now comes from environment variable
SSH_USER="ubuntu"

# --- Get User Input ---
read -p "Enter Target Private IP (e.g., 10.0.101.10 for manager): " TARGET_PRIVATE_IP
read -p "Enter Target Port (e.g., 80 for Nginx, 3000 for Grafana): " TARGET_PORT
read -p "Enter Local Port (e.g., 8080 for Nginx, 3000 for Grafana): " LOCAL_PORT

# --- Input Validation (basic) ---
if [ -z "$TARGET_PRIVATE_IP" ] || [ -z "$TARGET_PORT" ] || [ -z "$LOCAL_PORT" ]; then
  echo "Error: All inputs are required."
  exit 1
fi

# --- Terraform Output ---
# This part is now handled by setup_project_env.sh
BASTION_PUBLIC_IP="$BASTION_PUBLIC_IP" # Now comes from environment variable

# --- SSH Tunnel ---
echo "Attempting to establish SSH tunnel to $TARGET_PRIVATE_IP:$TARGET_PORT via local port $LOCAL_PORT..."
echo "Local: http://localhost:$LOCAL_PORT"
echo "Via Bastion: $SSH_USER@$BASTION_PUBLIC_IP"
echo "To Target Service: $TARGET_PRIVATE_IP:$TARGET_PORT"

# -f: Go to background after authentication
# -N: Do not execute a remote command (useful for just forwarding ports)
# -L <local_port>:<remote_host>:<remote_port>
ssh -i "$SSH_KEY_PATH" -fN -L "$LOCAL_PORT":"$TARGET_PRIVATE_IP":"$TARGET_PORT" "$SSH_USER"@"$BASTION_PUBLIC_IP"

if [ $? -eq 0 ]; then
  echo "SSH tunnel established successfully in the background."
  echo "You can now access the service at http://localhost:$LOCAL_PORT"
  echo "To kill the tunnel, find the ssh process (e.g., ps aux | grep 'ssh -i ...') and kill it."
else
  echo "Failed to establish SSH tunnel."
fi
