#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_ROOT=$(cd -- "$SCRIPT_DIR/../../.." && pwd)
DOWNLOAD_DIR="$SCRIPT_DIR/download"
OUTPUT_DIR="${1:-$SCRIPT_DIR/templates}"
SAMPLE_FILE="${SAMPLE_FILE:-}"
CLONE_ONLY="${CLONE_ONLY:-false}"

# Find sample config automatically.
if [[ -z "$SAMPLE_FILE" ]]; then
  SAMPLE_FILE=$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f \( -name '*.txt' -o -name '*.cfg' -o -name '*.conf' \) | head -n 1 || true)
fi

if [[ -z "$SAMPLE_FILE" ]]; then
  echo "No sample configuration found. Place AWS download under $DOWNLOAD_DIR." >&2
  exit 1
fi

TMP_OUTPUT=$(mktemp -d)
trap 'rm -rf "$TMP_OUTPUT"' EXIT

generate_from_sample() {
  local sample_file="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  extract_between() {
    local section="$1"
    local key="$2"
    awk -v sec="$section" -v key="$key" '
      $0 ~ "^conn " { current="" }
      $0 ~ "^conn " sec { current=sec; next }
      current==sec {
        line=$0
        gsub(/^[ \t]+/, "", line)
        if (line !~ key) next
        split(line, arr, "=")
        gsub(/^[ \t]+|[ \t]+$/, "", arr[2])
        print arr[2]
        exit
      }
    ' "$sample_file"
  }

  local left_id="$(extract_between "Tunnel1" "^leftid=")"
  local left_subnet="$(extract_between "Tunnel1" "^leftsubnet=")"
  local right_subnet="$(extract_between "Tunnel1" "^rightsubnet=")"
  local ike_suite="$(extract_between "Tunnel1" "^ike=")"
  local esp_suite="$(extract_between "Tunnel1" "^esp=")"
  local ikelifetime="$(extract_between "Tunnel1" "^ikelifetime=")"
  local lifetime="$(extract_between "Tunnel1" "^lifetime=")"
  local dpddelay="$(extract_between "Tunnel1" "^dpddelay=")"
  local dpdtimeout="$(extract_between "Tunnel1" "^dpdtimeout=")"
  local dpdaction="$(extract_between "Tunnel1" "^dpdaction=")"
  local right1="$(extract_between "Tunnel1" "^right=")"
  local right2="$(extract_between "Tunnel2" "^right=")"
  local rightid1="$(extract_between "Tunnel1" "^rightid=")"
  local rightid2="$(extract_between "Tunnel2" "^rightid=")"

  local onprem_override="${ONPREM_CIDR_OVERRIDE:-}"
  local vpc_override="${AWS_VPC_CIDR_OVERRIDE:-}"

  if [[ -n "$onprem_override" && ( -z "$left_subnet" || "$left_subnet" == "0.0.0.0/0" ) ]]; then
    left_subnet="$onprem_override"
  fi

  if [[ -n "$vpc_override" && ( -z "$right_subnet" || "$right_subnet" == "0.0.0.0/0" ) ]]; then
    right_subnet="$vpc_override"
  fi

  local psk1="$(grep ': PSK' "$sample_file" | sed -n '1s/.*PSK "\([^"]\+\)".*/\1/p')"
  local psk2="$(grep ': PSK' "$sample_file" | sed -n '2s/.*PSK "\([^"]\+\)".*/\1/p')"

  : "${left_id:?Could not parse leftid}"
  : "${right1:?Could not parse Tunnel1 right}"
  : "${right2:?Could not parse Tunnel2 right}"
  : "${psk1:?Could not parse Tunnel1 PSK}"
  : "${psk2:?Could not parse Tunnel2 PSK}"

  cat <<CONF >"$output_dir/ipsec.conf"
config setup
  charondebug="ike 1, knl 1, cfg 2"
  uniqueids=no

conn aws-tunnel-1
  auto=start
  type=tunnel
  keyexchange=ikev1
  authby=psk
  left=%defaultroute
  leftid=${left_id}
  leftsubnet=${left_subnet:-192.168.35.0/24}
  right=${right1}
  rightid=${rightid1:-$right1}
  rightsubnet=${right_subnet:-10.0.0.0/16}
  ike=${ike_suite:-aes128-sha1-modp1024}
  esp=${esp_suite:-aes128-sha1-modp1024}
  ikelifetime=${ikelifetime:-28800s}
  lifetime=${lifetime:-3600s}
  dpddelay=${dpddelay:-10s}
  dpdtimeout=${dpdtimeout:-30s}
  dpdaction=${dpdaction:-restart}

conn aws-tunnel-2
  also=aws-tunnel-1
  right=${right2}
  rightid=${rightid2:-$right2}
CONF

  cat <<SECRETS >"$output_dir/ipsec.secrets"
${left_id} ${right1} : PSK "${psk1}"
${left_id} ${right2} : PSK "${psk2}"
SECRETS

  cat <<INFO
Generated files:
  $output_dir/ipsec.conf
  $output_dir/ipsec.secrets
INFO
}

generate_from_sample "$SAMPLE_FILE" "$TMP_OUTPUT"

echo "Generated files in $TMP_OUTPUT"

if [[ "$CLONE_ONLY" != "true" ]]; then
  cp "$TMP_OUTPUT/ipsec.conf" "$OUTPUT_DIR/ipsec.conf.local"
  cp "$TMP_OUTPUT/ipsec.secrets" "$OUTPUT_DIR/ipsec.secrets.local"
  echo "Wrote sanitized copies to $OUTPUT_DIR/ipsec.conf.local and ipsec.secrets.local"
fi

echo "Finished"
