#!/bin/bash

# Enhanced SSH tunnel helper for Swarm services.
# - Lists services with published ports via docker service ls
# - Allows selecting a single service/port or forwarding all published ports at once
# - Falls back to manual entry when needed

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
source "${SCRIPT_DIR}/setup_env.sh"

SSH_USER="ubuntu"
DEFAULT_TARGET_HOST="swarm-manager"
BASTION_PUBLIC_IP="$BASTION_PUBLIC_IP"

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    if lsof -ti -sTCP:LISTEN -P -i "TCP:${port}" >/dev/null 2>&1; then
      return 0
    fi
  elif command -v ss >/dev/null 2>&1; then
    if ss -tln | awk '{print $4}' | grep -q ":${port}$"; then
      return 0
    fi
  fi
  return 1
}

cleanup_existing_tunnel() {
  local port="$1"
  local cleaned=false

  if command -v lsof >/dev/null 2>&1; then
    while read -r pid; do
      [ -z "$pid" ] && continue
      local cmd
      cmd=$(ps -p "$pid" -o comm= 2>/dev/null || true)
      if [ "$cmd" != "ssh" ]; then
        continue
      fi
      local args
      args=$(ps -p "$pid" -o args= 2>/dev/null || true)
      if echo "$args" | grep -q -- "-L ${port}:"; then
        if kill "$pid" >/dev/null 2>&1; then
          cleaned=true
        fi
      fi
    done < <(lsof -ti -sTCP:LISTEN -P -i "TCP:${port}" 2>/dev/null)
  fi

  if [ "$cleaned" = true ]; then
    sleep 1
    echo "ℹ️  Closed existing SSH tunnel on local port $port"
  fi
}

open_tunnel() {
  local local_port="$1"
  local remote_host="$2"
  local target_port="$3"
  local label="$4"

  cleanup_existing_tunnel "$local_port"

  if port_in_use "$local_port"; then
    echo "⚠️  Local port $local_port already in use. Skipping $label." >&2
    return 1
  fi

  echo "Opening tunnel for $label: localhost:$local_port -> ${remote_host}:$target_port"

  local -a ssh_cmd
  ssh_cmd=(ssh -fN -L "${local_port}:127.0.0.1:${target_port}")

  if [[ "$remote_host" == *@* ]]; then
    ssh_cmd+=(-J "${SSH_USER}@${BASTION_PUBLIC_IP}" "$remote_host")
  elif [[ "$remote_host" =~ ^[0-9.]+$ ]]; then
    ssh_cmd+=(-J "${SSH_USER}@${BASTION_PUBLIC_IP}" "${SSH_USER}@${remote_host}")
  else
    ssh_cmd+=("$remote_host")
  fi

  if "${ssh_cmd[@]}"; then
    echo "✅ Tunnel ready at http://localhost:$local_port"
    return 0
  else
    echo "❌ Failed to establish tunnel for $label" >&2
    return 1
  fi
}

resolve_service_host() {
  local service_name="$1"
  local node_name
  node_name=$(docker service ps "$service_name" --format '{{.Node}}' 2>/dev/null | head -n1)

  if [ -z "$node_name" ]; then
    echo "$DEFAULT_TARGET_HOST"
    return
  fi

  local node_ip
  node_ip=$(docker node inspect "$node_name" --format '{{.Status.Addr}}' 2>/dev/null || true)

  if [ -z "$node_ip" ]; then
    echo "$DEFAULT_TARGET_HOST"
    return
  fi

  if [ "$node_ip" = "$MANAGER_PRIVATE_IP" ]; then
    echo "swarm-manager"
    return
  fi

  local idx=1
  for ip in $WORKER_PRIVATE_IPS; do
    if [ "$node_ip" = "$ip" ]; then
      echo "worker$idx"
      return
    fi
    idx=$((idx+1))
  done

  echo "$node_ip"
}

fetch_service_ports() {
  local service_name="$1"
  docker service inspect "$service_name" \
    --format '{{range .Endpoint.Ports}}{{.PublishedPort}}|{{.TargetPort}}|{{.Protocol}}{{"\n"}}{{end}}' 2>/dev/null || true
}

mapfile -t SERVICE_LINES < <(docker service ls --format '{{.Name}}|{{if .Ports}}{{.Ports}}{{end}}' 2>/dev/null || true)

declare -A SERVICE_NAMES
SELECTION=""

if [ "${#SERVICE_LINES[@]}" -gt 0 ]; then
  echo
  echo "Available services with published ports:"
  echo "[0] Manual entry"
  echo "[A] Forward ALL published ports"
  idx=1
  for line in "${SERVICE_LINES[@]}"; do
    name="${line%%|*}"
    ports="${line#*|}"
    [ -z "$ports" ] && ports="(no published ports)"
    printf '[%d] %s -> %s\n' "$idx" "$name" "$ports"
    SERVICE_NAMES[$idx]="$name"
    ((idx++))
  done
  echo
  read -rp "Select option: " SELECTION || true
fi

declare -a TUNNEL_TASKS
TUNNEL_TASKS=()
TARGET_HOST="$DEFAULT_TARGET_HOST"

if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -gt 0 ] && [ "$SELECTION" -le "${#SERVICE_LINES[@]}" ]; then
  SERVICE_NAME="${SERVICE_NAMES[$SELECTION]}"
  echo "Selected service: $SERVICE_NAME"
  mapfile -t PORT_LINES < <(fetch_service_ports "$SERVICE_NAME")

  if [ "${#PORT_LINES[@]}" -eq 0 ]; then
    echo "Service has no published ports. Switching to manual entry."
  else
    declare -A PORT_MAP
    port_idx=1
    echo "Published ports for $SERVICE_NAME:"
    for port_line in "${PORT_LINES[@]}"; do
      [ -z "$port_line" ] && continue
      published="${port_line%%|*}"
      rest="${port_line#*|}"
      target="${rest%%|*}"
      proto="${rest##*|}"
      printf '[%d] Published %s -> Target %s (%s)\n' "$port_idx" "$published" "$target" "$proto"
      PORT_MAP[$port_idx]="$published:$target:$proto"
      ((port_idx++))
    done

    if [ "${#PORT_MAP[@]}" -gt 0 ]; then
      read -rp "Select port number: " PORT_SELECTION || true
      if [[ "$PORT_SELECTION" =~ ^[0-9]+$ ]] && [ -n "${PORT_MAP[$PORT_SELECTION]:-}" ]; then
        mapping="${PORT_MAP[$PORT_SELECTION]}"
        IFS=':' read -r LOCAL_PORT TARGET_PORT _ <<<"$mapping"
        TARGET_HOST=$(resolve_service_host "$SERVICE_NAME")
        TUNNEL_TASKS+=("$LOCAL_PORT|$TARGET_HOST|$TARGET_PORT|$SERVICE_NAME")
        read -rp "Target host alias or IP [default: $TARGET_HOST]: " input_host || true
        if [ -n "$input_host" ]; then
          TARGET_HOST="$input_host"
          TUNNEL_TASKS[-1]="$LOCAL_PORT|$TARGET_HOST|$TARGET_PORT|$SERVICE_NAME"
        fi
      else
        echo "Invalid selection. Switching to manual entry."
      fi
    fi
  fi
elif [[ "$SELECTION" =~ ^[Aa]$ ]]; then
  echo "Forwarding all published ports for every service..."
  for line in "${SERVICE_LINES[@]}"; do
    service="${line%%|*}"
    resolved_host=$(resolve_service_host "$service")
    mapfile -t PORT_LINES < <(fetch_service_ports "$service")
    for port_line in "${PORT_LINES[@]}"; do
      [ -z "$port_line" ] && continue
      IFS='|' read -r published target _ <<<"$port_line"
      [ -z "$published" ] && continue
      TUNNEL_TASKS+=("$published|$resolved_host|$target|$service")
    done
  done
else
  echo
  echo "Manual configuration"
  read -rp "Enter Target host alias or IP [default: $DEFAULT_TARGET_HOST]: " input_host || true
  if [ -n "$input_host" ]; then
    TARGET_HOST="$input_host"
  else
    TARGET_HOST="$DEFAULT_TARGET_HOST"
  fi
  read -rp "Enter Target Port (remote service port, e.g., 3000): " TARGET_PORT || true
  read -rp "Enter Local Port (local forward port, e.g., 3000): " LOCAL_PORT || true
  if [ -n "$TARGET_PORT" ] && [ -n "$LOCAL_PORT" ]; then
    TUNNEL_TASKS+=("$LOCAL_PORT|$TARGET_HOST|$TARGET_PORT|manual")
  fi
fi

if [ "${#TUNNEL_TASKS[@]}" -eq 0 ]; then
  echo "No tunnel tasks to execute. Exiting."
  exit 0
fi

for task in "${TUNNEL_TASKS[@]}"; do
  IFS='|' read -r local_port target_host target_port label <<<"$task"
  open_tunnel "$local_port" "$target_host" "$target_port" "$label"
done

echo "Done."
