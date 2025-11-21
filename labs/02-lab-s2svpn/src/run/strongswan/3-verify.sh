#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

echo "[+] Restarting strongSwan"
if command -v systemctl >/dev/null 2>&1; then
  systemctl restart strongswan-starter || true
fi
ipsec restart

echo "[+] Current strongSwan status"
ipsec statusall
