#!/bin/bash

# Enhanced SSH tunnel helper for Swarm services.
# - Lists services with published ports via docker service ls
# - Allows selecting a single service/port or forwarding all published ports at once
# - Falls back to manual entry when needed

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

if [ "${SETUP_ENV_FORCE:-}" = "1" ] || [ -z "${SETUP_ENV_INITIALIZED:-}" ]; then
  source "${SCRIPT_DIR}/setup_env.sh"
fi

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

node_alias_from_node() {
  local node_name="$1"
  local node_ip
  node_ip=$(docker node inspect "$node_name" --format '{{ .Status.Addr }}' 2>/dev/null || true)

  if [ -n "$node_ip" ]; then
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
    return
  fi

  echo "$node_name"
}

service_task_summary() {
  local service_name="$1"
  local -a task_lines=()
  mapfile -t task_lines < <(docker service ps "$service_name" --format '{{.Node}}|{{.DesiredState}}|{{.CurrentState}}' 2>/dev/null || true)

  if [ "${#task_lines[@]}" -eq 0 ]; then
    echo "${DEFAULT_TARGET_HOST}|No tasks scheduled"
    return
  fi

  declare -A alias_counts
  declare -A alias_states
  declare -A alias_seen
  local -a alias_order=()
  local default_host=""

  local line node desired current state_word alias
  for line in "${task_lines[@]}"; do
    [ -z "$line" ] && continue
    node=${line%%|*}
    rest=${line#*|}
    desired=${rest%%|*}
    current=${rest#*|}
    state_word=${current%% *}
    alias=$(node_alias_from_node "$node")

    if [ -z "${alias_seen[$alias]:-}" ]; then
      alias_seen[$alias]=1
      alias_order+=("$alias")
    fi

    alias_counts[$alias]=$(( ${alias_counts[$alias]:-0} + 1 ))

    if [ -z "$state_word" ]; then
      state_word="$current"
    fi

    if [ -z "${alias_states[$alias]:-}" ] || [ "$state_word" = "Running" ]; then
      alias_states[$alias]="$state_word"
    fi

    if [ -z "$default_host" ] && [ "$desired" = "Running" ]; then
      default_host="$alias"
    fi
  done

  if [ -z "$default_host" ] && [ "${#alias_order[@]}" -gt 0 ]; then
    default_host="${alias_order[0]}"
  fi

  if [ -z "$default_host" ]; then
    default_host="$DEFAULT_TARGET_HOST"
  fi

  local -a summary_parts=()
  local alias_item count state
  for alias_item in "${alias_order[@]}"; do
    count=${alias_counts[$alias_item]:-0}
    state=${alias_states[$alias_item]:-Unknown}
    if [ "$count" -gt 1 ]; then
      summary_parts+=("$alias_item x$count ($state)")
    else
      summary_parts+=("$alias_item ($state)")
    fi
  done

  local summary
  if [ "${#summary_parts[@]}" -gt 0 ]; then
    summary=$(printf '%s, ' "${summary_parts[@]}")
    summary=${summary%, }
  else
    summary="No tasks scheduled"
  fi

  echo "$default_host|$summary"
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
  local summary
  summary=$(service_task_summary "$service_name")
  echo "${summary%%|*}"
}

fetch_service_ports() {
  local service_name="$1"
  docker service inspect "$service_name" \
    --format '{{range .Endpoint.Ports}}{{.PublishedPort}}|{{.TargetPort}}|{{.Protocol}}{{"\n"}}{{end}}' 2>/dev/null || true
}

service_ports_summary() {
  local service_name="$1"
  local -a ports
  mapfile -t ports < <(fetch_service_ports "$service_name")
  if [ "${#ports[@]}" -eq 0 ]; then
    echo "--"
    return
  fi

  local -a parts=()
  local line published rest target proto display
  for line in "${ports[@]}"; do
    [ -z "$line" ] && continue
    published="${line%%|*}"
    rest="${line#*|}"
    target="${rest%%|*}"
    proto="${rest##*|}"
    if [ -z "$published" ]; then
      continue
    fi
    [ -z "$proto" ] && proto="tcp"
    if [ "$published" = "$target" ]; then
      display="${published}/${proto}"
    else
      display="${published}->${target}/${proto}"
    fi
    parts+=("$display")
  done

  if [ "${#parts[@]}" -eq 0 ]; then
    echo "--"
  else
    printf '%s' "${parts[0]}"
    if [ "${#parts[@]}" -gt 1 ]; then
      local idx
      for ((idx=1; idx<${#parts[@]}; idx++)); do
        printf ', %s' "${parts[$idx]}"
      done
    fi
    echo
  fi
}

mapfile -t SERVICE_LIST < <(docker service ls --format '{{.ID}}|{{.Name}}|{{.Replicas}}' 2>/dev/null || true)

declare -A SERVICE_IDS
declare -A SERVICE_NAMES
declare -A SERVICE_REPLICAS
declare -A SERVICE_DEFAULT_HOST
declare -A SERVICE_SUMMARY
declare -A SERVICE_PORT_SUMMARY
SERVICE_COUNT=${#SERVICE_LIST[@]}
SELECTION=""

if [ "$SERVICE_COUNT" -gt 0 ]; then
  echo
  echo "Current cluster services (published ports & nodes):"
  printf '%-4s %-12s %-28s %-22s %-45s %-15s\n' "Idx" "ID" "Service" "Ports" "Nodes" "Default Host"
  printf '%s\n' "----------------------------------------------------------------------------------------------------------------------------"
  echo "[0] Manual entry"
  echo "[A] Forward ALL published ports"
  idx=1
  for service_line in "${SERVICE_LIST[@]}"; do
    service_id="${service_line%%|*}"
    rest="${service_line#*|}"
    name="${rest%%|*}"
    replicas="${rest##*|}"
    ports=$(service_ports_summary "$name")
    summary_pair=$(service_task_summary "$name")
    default_host="${summary_pair%%|*}"
    summary_text="${summary_pair#*|}"
    [ -z "$ports" ] && ports="--"
    [ -z "$summary_text" ] && summary_text="No tasks scheduled"
    [ -z "$default_host" ] && default_host="$DEFAULT_TARGET_HOST"
    SERVICE_IDS[$idx]="$service_id"
    SERVICE_DEFAULT_HOST[$idx]="$default_host"
    SERVICE_SUMMARY[$idx]="$summary_text"
    SERVICE_PORT_SUMMARY[$idx]="$ports"
    SERVICE_NAMES[$idx]="$name"
    SERVICE_REPLICAS[$idx]="$replicas"
    printf '[%d] %-12s %-25s %-22s %-45s %-15s\n' "$idx" "$service_id" "$name" "$ports" "$summary_text" "$default_host"
    ((idx++))
  done
  echo
  read -rp "Select option: " SELECTION || true
fi

declare -a TUNNEL_TASKS
TUNNEL_TASKS=()
TARGET_HOST="$DEFAULT_TARGET_HOST"

if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -gt 0 ] && [ "$SELECTION" -le "$SERVICE_COUNT" ]; then
  SERVICE_NAME="${SERVICE_NAMES[$SELECTION]}"
  SERVICE_SUMMARY_TEXT="${SERVICE_SUMMARY[$SELECTION]:-No tasks scheduled}"
  TARGET_HOST_DEFAULT="${SERVICE_DEFAULT_HOST[$SELECTION]:-$DEFAULT_TARGET_HOST}"
  echo "Selected service: $SERVICE_NAME"
  echo " - Nodes: $SERVICE_SUMMARY_TEXT"
  echo " - Default host: $TARGET_HOST_DEFAULT"
  mapfile -t PORT_LINES < <(fetch_service_ports "$SERVICE_NAME")

  if [ "${#PORT_LINES[@]}" -eq 0 ]; then
    echo "Service has no published ports. Switching to manual entry."
  else
    declare -A PORT_MAP
    declare -A PORT_VALUE_MAP
    declare -a PORT_ORDER=()
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
      if [ -n "$published" ]; then
        PORT_VALUE_MAP[$published]="$port_idx"
      fi
      PORT_ORDER+=("$port_idx")
      ((port_idx++))
    done

    if [ "${#PORT_MAP[@]}" -gt 0 ]; then
      default_port_choice=1
      prompt_msg="Select port number [default: ${default_port_choice}, 'A' for all, or type published port]: "
      read -rp "$prompt_msg" PORT_SELECTION || true
      if [ -z "$PORT_SELECTION" ]; then
        PORT_SELECTION="$default_port_choice"
      fi

      if [[ "$PORT_SELECTION" =~ ^[Aa]$ ]]; then
        for key in "${PORT_ORDER[@]}"; do
          mapping="${PORT_MAP[$key]}"
          IFS=':' read -r LOCAL_PORT TARGET_PORT _ <<<"$mapping"
          TUNNEL_TASKS+=("$LOCAL_PORT|$TARGET_HOST_DEFAULT|$TARGET_PORT|$SERVICE_NAME")
        done
        echo "Forwarding all published ports for $SERVICE_NAME"
      else
        selected_index=""
        if [[ "$PORT_SELECTION" =~ ^[0-9]+$ ]] && [ -n "${PORT_MAP[$PORT_SELECTION]:-}" ]; then
          selected_index="$PORT_SELECTION"
        elif [[ "$PORT_SELECTION" =~ ^[0-9]+$ ]] && [ -n "${PORT_VALUE_MAP[$PORT_SELECTION]:-}" ]; then
          selected_index="${PORT_VALUE_MAP[$PORT_SELECTION]}"
        fi

        if [ -n "$selected_index" ]; then
          mapping="${PORT_MAP[$selected_index]}"
          IFS=':' read -r PUBLISHED_PORT TARGET_PORT _ <<<"$mapping"
          TARGET_HOST="$TARGET_HOST_DEFAULT"
          read -rp "Local port to bind [default: $PUBLISHED_PORT]: " input_local || true
          if [ -n "$input_local" ]; then
            LOCAL_PORT="$input_local"
          else
            LOCAL_PORT="$PUBLISHED_PORT"
          fi
          TUNNEL_TASKS+=("$LOCAL_PORT|$TARGET_HOST|$TARGET_PORT|$SERVICE_NAME")
        else
          echo "Invalid selection. Switching to manual entry."
        fi
      fi
    fi
  fi
elif [[ "$SELECTION" =~ ^[Aa]$ ]]; then
  echo "Forwarding all published ports for every service..."
  for service_line in "${SERVICE_LIST[@]}"; do
    rest="${service_line#*|}"
    service_name="${rest%%|*}"
    resolved_host=$(resolve_service_host "$service_name")
    mapfile -t PORT_LINES < <(fetch_service_ports "$service_name")
    for port_line in "${PORT_LINES[@]}"; do
      [ -z "$port_line" ] && continue
      IFS='|' read -r published target _ <<<"$port_line"
      [ -z "$published" ] && continue
      TUNNEL_TASKS+=("$published|$resolved_host|$target|$service_name")
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
  if [ -n "$TARGET_PORT" ]; then
    if [ -z "$LOCAL_PORT" ]; then
      LOCAL_PORT="$TARGET_PORT"
    fi
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
