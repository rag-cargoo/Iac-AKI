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

# --- Determine absolute paths ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)
TERRAFORM_ENVIRONMENT=${TERRAFORM_ENVIRONMENT:-production}

echo "Setting up project environment (Terraform env: $TERRAFORM_ENVIRONMENT)..."
TERRAFORM_DIR=$(cd "$PROJECT_ROOT/infra/terraform/envs/$TERRAFORM_ENVIRONMENT" &> /dev/null && pwd)

if [ -z "$TERRAFORM_DIR" ] || [ ! -d "$TERRAFORM_DIR" ]; then
    echo "⚠️  Terraform environment directory를 찾을 수 없습니다: $PROJECT_ROOT/infra/terraform/envs/$TERRAFORM_ENVIRONMENT"
    return 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠️  python3 명령을 찾을 수 없습니다. Python 3를 설치한 뒤 다시 실행하세요."
    return 1
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 1: Export Terraform outputs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

terraform_values=$(python3 - "$TERRAFORM_DIR" <<'PY'
import json
import subprocess
import sys

tf_dir = sys.argv[1]

try:
    result = subprocess.run(
        ["terraform", f"-chdir={tf_dir}", "output", "-json"],
        check=True,
        capture_output=True,
        text=True,
    )
except FileNotFoundError:
    sys.stderr.write("terraform 명령을 찾을 수 없습니다. Terraform을 설치하거나 PATH를 확인하세요.\n")
    sys.exit(1)
except subprocess.CalledProcessError as exc:
    message = exc.stderr or "terraform output 명령이 실패했습니다.\n"
    sys.stderr.write(message)
    sys.exit(2)

try:
    outputs = json.loads(result.stdout)
except json.JSONDecodeError:
    sys.stderr.write("terraform output JSON을 파싱하지 못했습니다.\n")
    sys.exit(3)

required_keys = (
    "bastion_public_ip",
    "ssh_key_file_path",
    "manager_private_ip",
    "worker_private_ips",
)
values = []
for key in required_keys:
    block = outputs.get(key)
    if not isinstance(block, dict) or "value" not in block:
        sys.stderr.write(
            f"필수 Terraform output '{key}'을(를) 찾을 수 없습니다. 'terraform apply'를 먼저 실행하세요.\n"
        )
        sys.exit(4)
    values.append(block["value"])

print(values[0])
print(values[1])
print(values[2])
workers = values[3] if isinstance(values[3], list) else []
print(" ".join(str(ip) for ip in workers if ip))
PY
)
status=$?

if [ $status -ne 0 ]; then
    echo "⚠️  Terraform outputs missing. Please run 'terraform apply' first."
    return 1
fi

mapfile -t _tf_lines <<< "$terraform_values"
BASTION_PUBLIC_IP=${_tf_lines[0]:-}
SSH_KEY_PATH=${_tf_lines[1]:-}
MANAGER_PRIVATE_IP=${_tf_lines[2]:-}
WORKER_PRIVATE_IPS=${_tf_lines[3]:-}

if [ -z "$BASTION_PUBLIC_IP" ] || [ -z "$SSH_KEY_PATH" ] || [ -z "$MANAGER_PRIVATE_IP" ]; then
    echo "⚠️  Terraform outputs incomplete. Please run 'terraform apply' first."
    return 1
fi

# Expand ~ in SSH key path
SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")

# Ensure worker list is trimmed
WORKER_PRIVATE_IPS=$(echo "$WORKER_PRIVATE_IPS")

echo "✅ BASTION_PUBLIC_IP=$BASTION_PUBLIC_IP"
echo "✅ SSH_KEY_PATH=$SSH_KEY_PATH"
echo "✅ MANAGER_PRIVATE_IP=$MANAGER_PRIVATE_IP"
if [ -n "$WORKER_PRIVATE_IPS" ]; then
    echo "✅ WORKER_PRIVATE_IPS=$WORKER_PRIVATE_IPS"
else
    echo "ℹ️  WORKER_PRIVATE_IPS 값이 비어 있습니다."
fi

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Configure SSH config
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 2: Configure SSH config"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SSH_CONFIG_FILE="$HOME/.ssh/config"
SSH_USER="ubuntu"
MANAGED_MARKER="setup_project_env.sh"

[ ! -f "$SSH_CONFIG_FILE" ] && touch "$SSH_CONFIG_FILE" && chmod 600 "$SSH_CONFIG_FILE"

add_ssh_host() {
    local host_name="$1"
    local host_ip="$2"
    local identity_file="$3"
    local proxy_jump="$4"

    local begin_marker="# >>> ${MANAGED_MARKER}: ${host_name} >>>"
    local end_marker="# <<< ${MANAGED_MARKER}: ${host_name} <<<"

    if grep -qF "$begin_marker" "$SSH_CONFIG_FILE"; then
        sed -i "/$begin_marker/,/$end_marker/d" "$SSH_CONFIG_FILE"
    fi

    {
        echo "$begin_marker"
        echo "Host $host_name"
        echo "    Hostname $host_ip"
        echo "    User $SSH_USER"
        echo "    IdentityFile $identity_file"
        if [ -n "$proxy_jump" ]; then
            echo "    ProxyJump $proxy_jump"
        fi
        echo "$end_marker"
        echo
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
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 2.5: Register SSH known_hosts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh-keyscan -H "$BASTION_PUBLIC_IP" >> ~/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan -H "$MANAGER_PRIVATE_IP" >> ~/.ssh/known_hosts 2>/dev/null || true
for ip in $WORKER_PRIVATE_IPS; do
    ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null || true
done

echo "✅ Hosts added to known_hosts to avoid authenticity prompt"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: SSH agent check & add key
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 3: SSH agent check & add key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! ssh-add -l > /dev/null 2>&1; then
    echo "⚠️ SSH agent not running. Starting ssh-agent..."
    eval "$(ssh-agent -s)" > /dev/null
fi

if ! ssh-add -l | grep -q "$(basename "$SSH_KEY_PATH")"; then
    if ssh-add "$SSH_KEY_PATH" > /dev/null 2>&1; then
        echo "✅ SSH key added to agent successfully."
    else
        echo "⚠️ Failed to add SSH key. Run manually: ssh-add $SSH_KEY_PATH"
    fi
else
    echo "✅ SSH agent is running and keys are loaded."
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Docker host setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Step 4: Docker host setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "ℹ️ To use Docker commands locally for the Swarm cluster, run:"
echo "   export DOCKER_HOST=\"ssh://swarm-manager\""

echo
echo "🎉 Project environment setup complete. You can now run Ansible commands and connection scripts."
