#!/bin/bash

# ===================================================================
# Project Environment Setup Script
# ===================================================================
# This script should be sourced: source setup_project_env.sh
# It sets up environment variables, SSH config, SSH agent, and Docker host
# ===================================================================

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 0: Initialize"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setting up project environment..."

# --- Determine absolute paths ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)
TERRAFORM_DIR=$(cd "$PROJECT_ROOT/Iac/TERRAFORM" &> /dev/null && pwd)

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 1: Export Terraform outputs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Fetch single-value outputs
BASTION_PUBLIC_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw bastion_public_ip 2>/dev/null || true)
SSH_KEY_PATH=$(terraform -chdir="$TERRAFORM_DIR" output -raw ssh_key_file_path 2>/dev/null || true)
MANAGER_PRIVATE_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw manager_private_ip 2>/dev/null || true)

# Fetch list output (worker IPs)
WORKER_PRIVATE_IPS=$(terraform -chdir="$TERRAFORM_DIR" output -json worker_private_ips 2>/dev/null | jq -r '.[]' | xargs)

if [ -z "$BASTION_PUBLIC_IP" ] || [ -z "$SSH_KEY_PATH" ] || [ -z "$MANAGER_PRIVATE_IP" ] || [ -z "$WORKER_PRIVATE_IPS" ]; then
    echo "⚠️  Terraform outputs missing. Please run 'terraform apply' first."
    return 1
fi

# Expand ~ in SSH key path
SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")

echo "✅ BASTION_PUBLIC_IP=$BASTION_PUBLIC_IP"
echo "✅ SSH_KEY_PATH=$SSH_KEY_PATH"
echo "✅ MANAGER_PRIVATE_IP=$MANAGER_PRIVATE_IP"
echo "✅ WORKER_PRIVATE_IPS=$WORKER_PRIVATE_IPS"

export BASTION_PUBLIC_IP SSH_KEY_PATH MANAGER_PRIVATE_IP WORKER_PRIVATE_IPS

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1.5: Cleanup old SSH host keys (to avoid fingerprint conflicts)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 1.5: Cleanup old SSH host keys"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh-keygen -R "$BASTION_PUBLIC_IP" 2>/dev/null
ssh-keygen -R "$MANAGER_PRIVATE_IP" 2>/dev/null
for ip in $WORKER_PRIVATE_IPS; do
    ssh-keygen -R "$ip" 2>/dev/null
done

echo "✅ Old SSH host keys removed from known_hosts"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 2: Configure SSH config"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SSH_CONFIG_FILE="$HOME/.ssh/config"
SSH_USER="ubuntu"

[ ! -f "$SSH_CONFIG_FILE" ] && touch "$SSH_CONFIG_FILE" && chmod 600 "$SSH_CONFIG_FILE"

add_ssh_host() {
    local host_name="$1"
    local host_ip="$2"
    local identity_file="$3"
    local proxy_jump="$4"

    # Remove existing managed block
    sed -i "/# Managed by setup_project_env.sh: $host_name/,/^\$/d" "$SSH_CONFIG_FILE"

    # Append new block
    {
        echo ""
        echo "# Managed by setup_project_env.sh: $host_name"
        echo "Host $host_name"
        echo "    Hostname $host_ip"
        echo "    User $SSH_USER"
        echo "    IdentityFile $identity_file"
        [ -n "$proxy_jump" ] && echo "    ProxyJump $proxy_jump"
        echo ""
    } >> "$SSH_CONFIG_FILE"
}

# Bastion host
add_ssh_host "bastion-host" "$BASTION_PUBLIC_IP" "$SSH_KEY_PATH" ""

# Manager node
add_ssh_host "swarm-manager" "$MANAGER_PRIVATE_IP" "$SSH_KEY_PATH" "ubuntu@$BASTION_PUBLIC_IP"

# Worker nodes
i=1
for ip in $WORKER_PRIVATE_IPS; do
    add_ssh_host "worker$i" "$ip" "$SSH_KEY_PATH" "ubuntu@$BASTION_PUBLIC_IP"
    ((i++))
done

echo "✅ SSH config updated with bastion, manager, and worker nodes"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2.5: Register hosts in known_hosts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 2.5: Register SSH known_hosts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh-keyscan -H "$BASTION_PUBLIC_IP" >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H "$MANAGER_PRIVATE_IP" >> ~/.ssh/known_hosts 2>/dev/null
for ip in $WORKER_PRIVATE_IPS; do
    ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null
done

echo "✅ Hosts added to known_hosts to avoid authenticity prompt"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 3: SSH agent check & add key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! ssh-add -l > /dev/null 2>&1; then
    echo "⚠️ SSH agent not running. Starting ssh-agent..."
    eval "$(ssh-agent -s)" > /dev/null
fi

if ! ssh-add -l | grep -q "$(basename "$SSH_KEY_PATH")"; then
    ssh-add "$SSH_KEY_PATH" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ SSH key added to agent successfully."
    else
        echo "⚠️ Failed to add SSH key. Run manually: ssh-add $SSH_KEY_PATH"
    fi
else
    echo "✅ SSH agent is running and keys are loaded."
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 4: Docker host setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "ℹ️ To use Docker commands locally for the Swarm cluster, run:"
echo "   export DOCKER_HOST=\"ssh://swarm-manager\""

echo
echo "🎉 Project environment setup complete. You can now run Ansible commands and connection scripts."
