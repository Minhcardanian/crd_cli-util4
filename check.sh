#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.sh"
LIB="$SCRIPT_DIR/lib.sh"

# Ensure core files exist
for f in "$CONFIG" "$LIB"; do
  [[ -f "$f" ]] || { echo "Required file not found: $f" >&2; exit 1; }
  source "$f"
done

# Ensure cardano-cli is available
command -v "$CARDANO_CLI" >/dev/null 2>&1 \
  || { echo "Error: CARDANO_CLI ('$CARDANO_CLI') not found" >&2; exit 1; }

# ─── Functions ─────────────────────────────────────────────────────────────────
check_utxo() {
  local address
  read -rp "Enter the address to query UTxO for: " address
  if [[ -z "$address" ]]; then
    echo "No address provided." >&2
    exit 1
  fi

  echo "Querying UTxO at address: $address"
  $CARDANO_CLI conway query utxo \
    --address "$address" \
    $NETWORK \
    --out-file /dev/stdout \
  || { echo "Failed to query UTxO." >&2; exit 1; }
}

check_txhash() {
  local txhash
  read -rp "Enter the transaction hash (txid): " txhash
  if [[ -z "$txhash" ]]; then
    echo "No transaction hash provided." >&2
    exit 1
  fi

  echo "Querying details for transaction: $txhash"
  local result
  result=$($CARDANO_CLI conway query utxo \
    --tx-in "$txhash" \
    $NETWORK 2>&1) \
      || { echo "Error or no such transaction: $result" >&2; exit 1; }

  echo "$result"
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
if (( $# != 1 )); then
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  utxo    Query UTxO for a given address
  txhash  Look up a transaction by its hash
EOF
  exit 1
fi

case "$1" in
  utxo)   check_utxo   ;;
  txhash) check_txhash ;;
  *) echo "Unknown command: $1" >&2; exit 1 ;;
esac
