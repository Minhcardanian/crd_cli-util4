#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"

# Ensure config & lib are present
if [[ ! -f "$CONFIG_FILE" || ! -f "$LIB_FILE" ]]; then
  echo "Required config.sh or lib.sh not found" >&2
  exit 1
fi

source "$CONFIG_FILE"
source "$LIB_FILE"

# ─── Invocation ────────────────────────────────────────────────────────────────
# Accept either "payment" or "script"; default to payment if unspecified
input_type="${1:-payment}"

select_utxo "$input_type"
check_command $? "UTxO selection failed"

echo
echo "✅ You selected UTxO: $SELECTED_UTXO"
