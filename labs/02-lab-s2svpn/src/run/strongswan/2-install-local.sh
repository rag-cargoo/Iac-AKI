#!/bin/bash
set -euo pipefail

CONF_SRC="${CONF_SRC-}"
SECRETS_SRC="${SECRETS_SRC-}"

if [[ $EUID -ne 0 ]]; then
  exec sudo -E CONF_SRC="$CONF_SRC" SECRETS_SRC="$SECRETS_SRC" "$0" "$@"
fi

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/templates"
CONF_SRC="${CONF_SRC:-$TEMPLATE_DIR/ipsec.conf.local}"
SECRETS_SRC="${SECRETS_SRC:-$TEMPLATE_DIR/ipsec.secrets.local}"

if [[ ! -f "$CONF_SRC" || ! -f "$SECRETS_SRC" ]]; then
  echo "Missing source files. Set CONF_SRC/SECRETS_SRC or generate .local files first." >&2
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)

CONF_DEST="/etc/ipsec.conf"
SECRETS_DEST="/etc/ipsec.secrets"

if [[ -f "$CONF_DEST" ]]; then
  cp "$CONF_DEST" "${CONF_DEST}.${TIMESTAMP}.bak"
  echo "Backed up $CONF_DEST to ${CONF_DEST}.${TIMESTAMP}.bak"
fi

if [[ -f "$SECRETS_DEST" ]]; then
  cp "$SECRETS_DEST" "${SECRETS_DEST}.${TIMESTAMP}.bak"
  echo "Backed up $SECRETS_DEST to ${SECRETS_DEST}.${TIMESTAMP}.bak"
fi

BEGIN_MARK='# BEGIN aws-s2s-managed'
END_MARK='# END aws-s2s-managed'

python3 - "$CONF_DEST" "$CONF_SRC" "$BEGIN_MARK" "$END_MARK" <<'PY'
import sys
from pathlib import Path

dest_path = Path(sys.argv[1])
src_path = Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]

new_block = f"{begin}\n{src_path.read_text().strip()}\n{end}\n"

if dest_path.exists():
    text = dest_path.read_text()
else:
    text = ""

if begin in text and end in text:
    import re
    pattern = rf"(?ms)^{begin}\n.*?^{end}\n?"
    text = re.sub(pattern, new_block, text)
else:
    text = text.rstrip() + ("\n\n" if text.strip() else "") + new_block

dest_path.write_text(text)
PY

python3 - "$SECRETS_DEST" "$SECRETS_SRC" "$BEGIN_MARK" "$END_MARK" <<'PY'
import sys
from pathlib import Path

dest_path = Path(sys.argv[1])
src_path = Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]

new_block = f"{begin}\n{src_path.read_text().strip()}\n{end}\n"

if dest_path.exists():
    text = dest_path.read_text()
else:
    text = ""

if begin in text and end in text:
    import re
    pattern = rf"(?ms)^{begin}\n.*?^{end}\n?"
    text = re.sub(pattern, new_block, text)
else:
    text = text.rstrip() + ("\n\n" if text.strip() else "") + new_block

dest_path.write_text(text)
PY

chmod 644 "$CONF_DEST"
chmod 600 "$SECRETS_DEST"

echo "Updated $CONF_DEST with block managed between $BEGIN_MARK / $END_MARK"
echo "Updated $SECRETS_DEST with block managed between $BEGIN_MARK / $END_MARK"

echo "--- $CONF_DEST (AWS managed block) ---"
sed -n "/$BEGIN_MARK/,/$END_MARK/p" "$CONF_DEST"

echo "--- $SECRETS_DEST (AWS managed block) ---"
sed -n "/$BEGIN_MARK/,/$END_MARK/p" "$SECRETS_DEST"
