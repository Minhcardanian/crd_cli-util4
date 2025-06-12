#!/usr/bin/env bash
set -euo pipefail

# ─── Setup & Config Loading ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"

for f in "$CONFIG_FILE" "$LIB_FILE"; do
  [[ -f "$f" ]] || { echo "Error: Missing $f" >&2; exit 1; }
  source "$f"
done

# ─── Helper to abort on failure ────────────────────────────────────────────────
check_command() {
  if [[ $1 -ne 0 ]]; then
    echo "Error: $2" >&2
    exit 1
  fi
}

# ─── Prompt user for delegation choice ─────────────────────────────────────────
echo "Select vote-delegation option:"
echo "  1) Always Abstain"
echo "  2) No Confidence"
echo "  3) Delegate to a DRep"
read -rp "Enter choice (1/2/3): " choice

case "$choice" in
  1) cert_args=(--always-abstain) ;;
  2) cert_args=(--always-no-confidence) ;;
  3)
    read -rp "Enter the DRep key hash: " drep_hash
    cert_args=(--drep-key-hash "$drep_hash")
    ;;
  *)
    echo "Invalid option." >&2
    exit 1
    ;;
esac

# ─── Build vote-delegation certificate ─────────────────────────────────────────
cert_file="vote-deleg.cert"
echo "Generating delegation certificate..."
"$CARDANO_CLI" conway stake-address vote-delegation-certificate \
  --stake-verification-key-file stake.vkey \
  "${cert_args[@]}" \
  --out-file "$cert_file"
check_command $? "Failed to create delegation certificate"

# ─── Select UTXO to cover fees ─────────────────────────────────────────────────
echo "Selecting UTxO to cover transaction fees..."
tx_in="$(
  "$CARDANO_CLI" conway query utxo \
    --address "$(< payment.addr)" \
    $NETWORK \
    --out-file /dev/stdout \
  | jq -r 'keys[0]'
)"
if [[ -z "$tx_in" ]]; then
  echo "No available UTxO to cover fees." >&2
  exit 1
fi

# ─── Build the delegation transaction ──────────────────────────────────────────
echo "Building delegation transaction..."
build_tx \
  --tx-in "$tx_in" \
  --change-address "$(< payment.addr)" \
  --certificate-file "$cert_file" \
  --witness-override 2 \
  --out-file deleg.tx
check_command $? "Failed to build delegation transaction"

# ─── Sign the transaction ──────────────────────────────────────────────────────
echo "Signing delegation transaction..."
sign_tx \
  --tx-body-file deleg.tx \
  --signing-key-file payment.skey \
  --signing-key-file stake.skey \
  --out-file deleg.signed
check_command $? "Failed to sign delegation transaction"

# ─── Submit and report ──────────────────────────────────────────────────────────
echo "Submitting delegation transaction..."
submit_tx --tx-file deleg.signed
check_command $? "Failed to submit delegation transaction"

txid=$("$CARDANO_CLI" conway transaction txid --tx-file deleg.signed)
if [[ -n "$txid" ]]; then
  echo "✅ Delegation successfully submitted!"
  echo "   TXID: $txid"
else
  echo "Error: Could not retrieve transaction ID." >&2
  exit 1
fi
