#!/bin/bash

# Script to set up local Docker client environment to connect to remote Docker Swarm via bastion.

set -e

# --- Configuration ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

TERRAFORM_DIR="${SCRIPT_DIR}/../../Iac/TERRAFORM"
SSH_CONFIG_FILE="$HOME/.ssh/config"
# Use absolute path for SSH_KEY_PATH
SSH_KEY_PATH="$HOME/.aws/key/test_key.pem" # Ensure this matches your actual key path

# --- Fetch IPs from Terraform Output ---
echo "Exporting Terraform outputs..."
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform directory not found at ${TERRAFORM_DIR}"
    exit 1
fi

# Capture terraform output as JSON
TERRAFORM_OUTPUT_JSON=$(terraform -chdir="$TERRAFORM_DIR" output -json)

# Parse JSON and export environment variables
export BASTION_PUBLIC_IP=$(echo "$TERRAFORM_OUTPUT_JSON" | jq -r '.bastion_public_ip.value')
export MANAGER_PRIVATE_IP=$(echo "$TERRAFORM_OUTPUT_JSON" | jq -r '.manager_private_ip.value')
export WORKER_PRIVATE_IPS=$(echo "$TERRAFORM_OUTPUT_JSON" | jq -r '.worker_private_ips.value[]' | tr '\n' ' ')
export SSH_KEY_PATH=$(echo "$TERRAFORM_OUTPUT_JSON" | jq -r '.ssh_key_file_path.value')

if [ -z "$BASTION_PUBLIC_IP" ] || [ -z "$MANAGER_PRIVATE_IP" ] || [ -z "$WORKER_PRIVATE_IPS" ] || [ -z "$SSH_KEY_PATH" ]; then
    echo "❌ ERROR: Required Terraform outputs are missing or empty. Please ensure 'terraform apply' was successful and outputs are defined."
    exit 1
fi

echo "✅ SUCCESS: Terraform outputs exported successfully."

# --- SSH Agent ---
echo "Checking SSH agent and adding key if necessary..."

# Ensure SSH_AUTH_SOCK is set and agent is running
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l > /dev/null 2>&1; then
  echo "SSH agent not running or key not loaded. Starting ssh-agent..."
  # Start ssh-agent and capture its output to set env vars
  eval "$(ssh-agent -s)" > /dev/null # Suppress default output
  if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "✅ SUCCESS: ssh-agent started."
  else
    echo "❌ ERROR: Failed to start ssh-agent. Cannot proceed without agent."
    exit 1
  fi
fi

# Add key to agent if not already added
if ! ssh-add -l | grep -q "$(basename "$SSH_KEY_PATH")"; then
  echo "Adding SSH key to agent..."
  if ssh-add "$SSH_KEY_PATH" 2>/dev/null; then # Suppress "Identity added" output
    echo "✅ SUCCESS: SSH key added to agent."
  else
    echo "❌ ERROR: Failed to add SSH key to agent. Check key path and permissions. Cannot proceed."
    exit 1 # This must be critical. If key isn't added, SSH will fail.
  fi
else
  echo "✅ SUCCESS: SSH key already in agent."
fi

echo "SSH key setup complete."

# --- Configure ~/.ssh/config ---
echo "Configuring ~/.ssh/config for swarm-manager..."

SSH_CONFIG_BLOCK="Host swarm-manager\n    Hostname $MANAGER_PRIVATE_IP\n    User ubuntu\n    IdentityFile $SSH_KEY_PATH\n    ProxyJump ubuntu@$BASTION_PUBLIC_IP"

# Check if ~/.ssh/config exists, create if not
if [ ! -f "$SSH_CONFIG_FILE" ]; then
    touch "$SSH_CONFIG_FILE"
    chmod 600 "$SSH_CONFIG_FILE"
fi

# Use awk to replace the block if it exists, otherwise append
awk -v block="$SSH_CONFIG_BLOCK" ' 
BEGIN { found = 0 }
/^Host swarm-manager$/ {
    print block
    found = 1
    while (getline && $0 !~ /^$/ && $0 !~ /^Host /) {}
    if ($0 ~ /^$/) { print "" } 
    next
}
{ print }
END {
    if (found == 0) {
        print ""
        print block
    }
}' "$SSH_CONFIG_FILE" > "${SSH_CONFIG_FILE}.tmp" && mv "${SSH_CONFIG_FILE}.tmp" "$SSH_CONFIG_FILE"

echo "Updated 'swarm-manager' entry in $SSH_CONFIG_FILE"

# --- Final Instructions ---
echo ""
echo "--------------------------------------------------------------------------------"
echo "IMPORTANT: To use Docker commands locally for the Swarm cluster, run the following command:"
echo "  export DOCKER_HOST=\"ssh://swarm-manager\""
echo "You can add this line to your ~/.bashrc or ~/.zshrc for permanent setup."
echo "--------------------------------------------------------------------------------"

echo "You can now run Ansible commands and connection scripts."