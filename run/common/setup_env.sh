#!/bin/bash
# Environment bootstrap (Terraform outputs + SSH setup + docker host)
# Designed to be *sourced*.
set -euo pipefail

print_banner(){
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔹 $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

CACHE_SCHEMA_VERSION=1
SSH_USER="ubuntu"
SSH_CONNECT_FLAGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10"
CACHE_FAILURE_REASON=""

load_cached_env(){
  if [ ! -f "$CACHE_FILE" ]; then
    return 1
  fi
  # shellcheck disable=SC1090
  source "$CACHE_FILE"
  return 0
}

validate_cached_env(){
  if [ "${CACHE_VERSION:-}" != "$CACHE_SCHEMA_VERSION" ]; then
    return 1
  fi
  if [ "${CACHED_TERRAFORM_ENVIRONMENT:-}" != "$TERRAFORM_ENVIRONMENT" ]; then
    return 1
  fi
  if [ -z "${BASTION_PUBLIC_IP:-}" ] || [ -z "${SSH_KEY_PATH:-}" ] || [ -z "${MANAGER_PRIVATE_IP:-}" ]; then
    return 1
  fi

  SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")
  if [ ! -f "$SSH_KEY_PATH" ]; then
    return 1
  fi

  if [ -z "${WORKER_PRIVATE_IPS+x}" ]; then
    WORKER_PRIVATE_IPS=""
  fi

  if [ -z "${SWARM_PROXY_HOST:-}" ]; then
    SWARM_PROXY_HOST="${SSH_USER}@${BASTION_PUBLIC_IP}"
  fi

  export BASTION_PUBLIC_IP SSH_KEY_PATH MANAGER_PRIVATE_IP WORKER_PRIVATE_IPS SWARM_PROXY_HOST

  local ssh_flags="$SSH_CONNECT_FLAGS"
  if ! ssh -i "$SSH_KEY_PATH" $ssh_flags "${SSH_USER}@${BASTION_PUBLIC_IP}" true >/dev/null 2>&1; then
    return 1
  fi

  if command -v docker >/dev/null 2>&1; then
    if ! DOCKER_HOST= DOCKER_CONTEXT= docker context inspect swarm-manager >/dev/null 2>&1; then
      return 1
    fi
    if ! DOCKER_HOST= DOCKER_CONTEXT= docker context use swarm-manager >/dev/null 2>&1; then
      return 1
    fi
    local -a node_hostnames=()
    if ! mapfile -t node_hostnames < <(DOCKER_CONTEXT=swarm-manager docker node ls --format '{{.Hostname}}' 2>/dev/null); then
      return 1
    fi
    local -a current_nodes_list=()
    local node_name node_ip
    for node_name in "${node_hostnames[@]}"; do
      [ -z "$node_name" ] && continue
      if ! node_ip=$(DOCKER_CONTEXT=swarm-manager docker node inspect "$node_name" --format '{{ .Status.Addr }}' 2>/dev/null); then
        return 1
      fi
      if [ -n "$node_ip" ]; then
        current_nodes_list+=("$node_ip")
      fi
    done
    if [ ${#current_nodes_list[@]} -eq 0 ]; then
      return 1
    fi
    local current_nodes
    if ! current_nodes=$(printf '%s\n' "${current_nodes_list[@]}" | LC_ALL=C sort -u); then
      return 1
    fi
    local -a expected_nodes_list=("$MANAGER_PRIVATE_IP")
    if [ -n "$WORKER_PRIVATE_IPS" ]; then
      # shellcheck disable=SC2206
      local -a worker_array=($WORKER_PRIVATE_IPS)
      expected_nodes_list+=("${worker_array[@]}")
    fi
    local expected_nodes
    if ! expected_nodes=$(printf '%s\n' "${expected_nodes_list[@]}" | LC_ALL=C sort -u); then
      return 1
    fi
    if [ "$current_nodes" != "$expected_nodes" ]; then
      return 1
    fi
  fi

  return 0
}

attempt_cached_bootstrap(){
  CACHE_FAILURE_REASON=""
  if [ -n "${SETUP_ENV_FORCE:-}" ]; then
    CACHE_FAILURE_REASON="forced"
    return 1
  fi
  if [ ! -f "$CACHE_FILE" ]; then
    CACHE_FAILURE_REASON="missing"
    return 1
  fi
  if ! load_cached_env; then
    CACHE_FAILURE_REASON="load_failed"
    return 1
  fi
  if ! validate_cached_env; then
    CACHE_FAILURE_REASON="invalid"
    return 1
  fi

  print_banner "Step 1 (cached): Terraform outputs"
  echo "✅ BASTION_PUBLIC_IP=$BASTION_PUBLIC_IP"
  echo "✅ SSH_KEY_PATH=$SSH_KEY_PATH"
  echo "✅ MANAGER_PRIVATE_IP=$MANAGER_PRIVATE_IP"
  [ -n "$WORKER_PRIVATE_IPS" ] && echo "✅ WORKER_PRIVATE_IPS=$WORKER_PRIVATE_IPS" || echo "ℹ️  No worker IPs"

  export SETUP_ENV_INITIALIZED=1
  echo
  print_banner "Complete"
  echo "🎉 Environment setup loaded from cache"
  echo "ℹ️  Use 'make setup_env_refresh' or set SETUP_ENV_FORCE=1 to refresh the environment."
  return 0
}

save_cache(){
  local tmp
  tmp=$(mktemp) || return 1
  {
    printf 'CACHE_VERSION=%q\n' "$CACHE_SCHEMA_VERSION"
    printf 'CACHED_TERRAFORM_ENVIRONMENT=%q\n' "$TERRAFORM_ENVIRONMENT"
    printf 'BASTION_PUBLIC_IP=%q\n' "$BASTION_PUBLIC_IP"
    printf 'SSH_KEY_PATH=%q\n' "$SSH_KEY_PATH"
    printf 'MANAGER_PRIVATE_IP=%q\n' "$MANAGER_PRIVATE_IP"
    printf 'WORKER_PRIVATE_IPS=%q\n' "$WORKER_PRIVATE_IPS"
    printf 'SWARM_PROXY_HOST=%q\n' "${SWARM_PROXY_HOST:-${SSH_USER}@${BASTION_PUBLIC_IP}}"
  } > "$tmp" || { rm -f "$tmp"; return 1; }
  chmod 600 "$tmp" || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$CACHE_FILE" || { rm -f "$tmp"; return 1; }
  return 0
}

print_banner "Step 0: Initialize"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)
CACHE_FILE="$SCRIPT_DIR/.setup_env_cache"
TERRAFORM_ENVIRONMENT=${TERRAFORM_ENVIRONMENT:-production}
TERRAFORM_DIR="$PROJECT_ROOT/src/iac/terraform/envs/$TERRAFORM_ENVIRONMENT"

if attempt_cached_bootstrap; then
  return 0
fi

if [ "$CACHE_FAILURE_REASON" = "forced" ]; then
  echo "ℹ️  Forced refresh requested; running full setup."
elif [ "$CACHE_FAILURE_REASON" = "invalid" ]; then
  echo "ℹ️  Cached environment stale or inconsistent; running full setup."
elif [ "$CACHE_FAILURE_REASON" = "load_failed" ]; then
  echo "ℹ️  Unable to read cached environment; running full setup."
fi

if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "⚠️  Terraform env dir not found: $TERRAFORM_DIR"
  return 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "⚠️  python3 not available"
  return 1
fi

print_banner "Step 1: Export Terraform outputs"
terraform_values=$(python3 - "$TERRAFORM_DIR" <<'PY'
import json
import subprocess
import sys

tf_dir = sys.argv[1]
result = subprocess.run([
    "terraform", f"-chdir={tf_dir}", "output", "-json"
], capture_output=True, text=True)
if result.returncode != 0:
    sys.stderr.write(result.stderr or "terraform output failed\n")
    sys.exit(1)
outputs = json.loads(result.stdout)
required = [
    "bastion_public_ip",
    "ssh_key_file_path",
    "manager_private_ips",
    "worker_private_ips",
]
values = []
for key in required:
    block = outputs.get(key)
    if not isinstance(block, dict) or "value" not in block:
        sys.stderr.write(f"missing terraform output: {key}\n")
        sys.exit(2)
    values.append(block["value"])
print(values[0])
print(values[1])
manager_ips = values[2] if isinstance(values[2], list) else []
print(manager_ips[0] if manager_ips else "")
workers = values[3] if isinstance(values[3], list) else []
print(" ".join(str(ip) for ip in workers if ip))
PY
)

mapfile -t _tf_lines <<<"$terraform_values"
BASTION_PUBLIC_IP=${_tf_lines[0]:-}
SSH_KEY_PATH=${_tf_lines[1]:-}
MANAGER_PRIVATE_IP=${_tf_lines[2]:-}
WORKER_PRIVATE_IPS=${_tf_lines[3]:-}

if [ -z "$BASTION_PUBLIC_IP" ] || [ -z "$SSH_KEY_PATH" ] || [ -z "$MANAGER_PRIVATE_IP" ]; then
  echo "⚠️  required Terraform outputs missing"
  return 1
fi

SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")
export BASTION_PUBLIC_IP SSH_KEY_PATH MANAGER_PRIVATE_IP WORKER_PRIVATE_IPS

echo "✅ BASTION_PUBLIC_IP=$BASTION_PUBLIC_IP"
echo "✅ SSH_KEY_PATH=$SSH_KEY_PATH"
echo "✅ MANAGER_PRIVATE_IP=$MANAGER_PRIVATE_IP"
[ -n "$WORKER_PRIVATE_IPS" ] && echo "✅ WORKER_PRIVATE_IPS=$WORKER_PRIVATE_IPS" || echo "ℹ️  No worker IPs"

print_banner "Step 1.5: Cleanup host keys"
SSH_DIR="$HOME/.ssh"
SSH_HOST_SETUP=true

if ! mkdir -p "$SSH_DIR" 2>/dev/null; then
  SSH_HOST_SETUP=false
  echo "ℹ️  Cannot access $SSH_DIR; skipping host key refresh"
fi

if [ "$SSH_HOST_SETUP" = true ] && [ ! -w "$SSH_DIR" ]; then
  SSH_HOST_SETUP=false
  echo "ℹ️  $SSH_DIR is not writable; skipping host key refresh"
fi

KNOWN_HOSTS_FILE="$SSH_DIR/known_hosts"
if [ "$SSH_HOST_SETUP" = true ] && touch "$KNOWN_HOSTS_FILE" 2>/dev/null; then
  chmod 600 "$KNOWN_HOSTS_FILE" 2>/dev/null || true
  ssh-keygen -R "$BASTION_PUBLIC_IP" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1 || true
  ssh-keygen -R "$MANAGER_PRIVATE_IP" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1 || true
  if [ -n "$WORKER_PRIVATE_IPS" ]; then
    for _ip in $WORKER_PRIVATE_IPS; do
      ssh-keygen -R "$_ip" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1 || true
    done
  fi
  ssh-keyscan -H "$BASTION_PUBLIC_IP" >> "$KNOWN_HOSTS_FILE" 2>/dev/null || true
  ssh-keyscan -H "$MANAGER_PRIVATE_IP" >> "$KNOWN_HOSTS_FILE" 2>/dev/null || true
  if [ -n "$WORKER_PRIVATE_IPS" ]; then
    for _ip in $WORKER_PRIVATE_IPS; do
      ssh-keyscan -H "$_ip" >> "$KNOWN_HOSTS_FILE" 2>/dev/null || true
    done
  fi
  echo "✅ Hosts added to known_hosts"
else
  echo "ℹ️  Cannot update $KNOWN_HOSTS_FILE; skipping"
fi

print_banner "Step 2: Configure SSH config"
SSH_CONFIG_FILE="$SSH_DIR/config"
SSH_USER="ubuntu"
MANAGED_MARKER="run/common/setup_env.sh"
SSH_CONFIG_OK=false

if [ "$SSH_HOST_SETUP" = true ]; then
  if [ ! -e "$SSH_CONFIG_FILE" ]; then
    if touch "$SSH_CONFIG_FILE" 2>/dev/null; then
      chmod 600 "$SSH_CONFIG_FILE" 2>/dev/null || true
      SSH_CONFIG_OK=true
    fi
  elif [ -w "$SSH_CONFIG_FILE" ]; then
    SSH_CONFIG_OK=true
  else
    echo "ℹ️  $SSH_CONFIG_FILE is not writable; skipping"
  fi
else
  echo "ℹ️  SSH directory not writable; skipping config updates"
fi

remove_host_block() {
  local host_name="$1"
  local tmp
  tmp=$(mktemp)
  awk -v marker="$host_name" -v tag="$MANAGED_MARKER" '
    $0 == "# Managed by " tag ": " marker {skip=1; next}
    skip && NF==0 {skip=0; next}
    !skip {print $0}
  ' "$SSH_CONFIG_FILE" > "$tmp"
  mv "$tmp" "$SSH_CONFIG_FILE"
}

add_ssh_host() {
  local host_name="$1"
  local host_ip="$2"
  local identity_file="$3"
  local proxy_jump="$4"
  if ! remove_host_block "$host_name"; then
    echo "ℹ️  Failed to update $SSH_CONFIG_FILE; skipping further SSH config changes"
    SSH_CONFIG_OK=false
    return 1
  fi
  {
    echo "# Managed by ${MANAGED_MARKER}: ${host_name}"
    echo "Host $host_name"
    echo "    Hostname $host_ip"
    echo "    User $SSH_USER"
    echo "    IdentityFile $identity_file"
    echo "    StrictHostKeyChecking no"
    echo "    UserKnownHostsFile /dev/null"
    echo "    BatchMode yes"
    echo "    IdentitiesOnly yes"
    [ -n "$proxy_jump" ] && echo "    ProxyJump $proxy_jump"
    echo
  } >> "$SSH_CONFIG_FILE"
}

if [ "$SSH_CONFIG_OK" = true ]; then
  if ! add_ssh_host "bastion-host" "$BASTION_PUBLIC_IP" "$SSH_KEY_PATH" ""; then
    SSH_CONFIG_OK=false
  fi
fi

if [ "$SSH_CONFIG_OK" = true ]; then
  if ! add_ssh_host "swarm-manager" "$MANAGER_PRIVATE_IP" "$SSH_KEY_PATH" "bastion-host"; then
    SSH_CONFIG_OK=false
  fi
fi

if [ "$SSH_CONFIG_OK" = true ] && [ -n "$WORKER_PRIVATE_IPS" ]; then
  idx=1
  for _ip in $WORKER_PRIVATE_IPS; do
    if ! add_ssh_host "worker$idx" "$_ip" "$SSH_KEY_PATH" "bastion-host"; then
      SSH_CONFIG_OK=false
      break
    fi
    idx=$((idx+1))
  done
fi

if [ "$SSH_CONFIG_OK" = true ]; then
  echo "✅ SSH config updated"
else
  echo "ℹ️  Cannot write to $SSH_CONFIG_FILE; skipping"
fi

PROXY_TARGET="${SSH_USER}@${BASTION_PUBLIC_IP}"
if [ "$SSH_CONFIG_OK" = true ]; then
  PROXY_TARGET="bastion-host"
fi
export SWARM_PROXY_HOST="$PROXY_TARGET"

print_banner "Step 2.5: Verify SSH connectivity"
SSH_TEST_FLAGS="$SSH_CONNECT_FLAGS"
if ssh -i "$SSH_KEY_PATH" $SSH_TEST_FLAGS "$SSH_USER@$BASTION_PUBLIC_IP" true >/dev/null 2>&1; then
  echo "✅ Bastion SSH connectivity verified"
else
  echo "❌ Unable to reach bastion host $BASTION_PUBLIC_IP with the provided key."
  echo "   Check that /home/aki/.aws/key/test_key.pem matches the instance key pair and permissions are 600."
  return 1
fi

if [ "$SSH_CONFIG_OK" = true ]; then
  if ssh $SSH_TEST_FLAGS swarm-manager true >/dev/null 2>&1; then
    echo "✅ swarm-manager reachable via ProxyJump"
  else
    echo "❌ Unable to reach swarm-manager via SSH config."
    echo "   Verify bastion access and rerun 'make setup_env'."
    return 1
  fi
else
  echo "ℹ️  SSH config not writable; skipping swarm-manager connectivity check"
fi

print_banner "Step 3: SSH agent check"
if ! ssh-add -l >/dev/null 2>&1; then
  echo "⚠️  ssh-agent not running. Attempting to start ssh-agent..."
  if ! eval "$(ssh-agent -s)" >/dev/null 2>&1; then
    echo "ℹ️  Unable to start ssh-agent in this environment; continuing without loading keys"
  fi
fi
if ssh-add -l >/dev/null 2>&1; then
  if ssh-add -l | grep -q "$(basename "$SSH_KEY_PATH")"; then
    echo "✅ SSH agent already has the key loaded."
  elif ssh-add "$SSH_KEY_PATH" >/dev/null 2>&1; then
    echo "✅ SSH key added to agent successfully."
  else
    echo "⚠️ Failed to add SSH key. Run manually: ssh-add $SSH_KEY_PATH"
  fi
else
  echo "ℹ️  SSH agent unavailable; skipping key load"
fi

print_banner "Step 4: Docker host"
echo "✅ Docker host configured via context"

if command -v docker >/dev/null 2>&1; then
  context_args=(--docker "host=ssh://swarm-manager")

  if ! DOCKER_HOST= DOCKER_CONTEXT= docker context inspect swarm-manager >/dev/null 2>&1; then
    DOCKER_HOST= DOCKER_CONTEXT= docker context rm -f swarm-manager >/dev/null 2>&1 || true
    if ! DOCKER_HOST= DOCKER_CONTEXT= docker context create "${context_args[@]}" swarm-manager >/dev/null 2>&1; then
      echo "❌ Failed to create docker context 'swarm-manager'"
      return 1
    fi
  else
    if ! DOCKER_HOST= DOCKER_CONTEXT= docker context update "${context_args[@]}" swarm-manager >/dev/null 2>&1; then
      echo "❌ Failed to update docker context 'swarm-manager'"
      return 1
    fi
  fi

  if DOCKER_HOST= DOCKER_CONTEXT= docker context use swarm-manager >/dev/null 2>&1; then
    echo "✅ Docker context 'swarm-manager' selected"
  else
    echo "❌ Unable to switch docker context automatically; run 'docker context use swarm-manager' manually"
    return 1
  fi
else
  echo "ℹ️  Docker CLI not available; skipping context configuration"
fi

echo
export SETUP_ENV_INITIALIZED=1

if ! save_cache; then
  echo "ℹ️  Unable to update cache at $CACHE_FILE"
fi

print_banner "Complete"
echo "🎉 Environment setup complete"
