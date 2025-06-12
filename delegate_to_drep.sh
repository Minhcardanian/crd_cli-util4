#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.sh"
LIB="$SCRIPT_DIR/lib.sh"

for f in "$CONFIG" "$LIB"; do
  [[ -f "$f" ]] || { echo "Required file not found: $f" >&2; exit 1; }
  source "$f"
done

# ─── Helpers ───────────────────────────────────────────────────────────────────
check_command() {
    if [[ $1 -ne 0 ]]; then
        echo "Error: $2" >&2
        exit 1
    fi
}

# ─── Prompt user for delegation choice ─────────────────────────────────────────
echo "Select a vote delegation option:"
echo "  1) Always Abstain"
echo "  2) No Confidence"
echo "  3) Delegate to specific DRep"
read -rp "Enter choice (1/2/3): " choice

case "$choice" in
    1)
        cert_flags=(--always-abstain)
        ;;
    2)
        cert_flags=(--always-no-confidence)
        ;;
    3)
        read -rp "Enter the DRep key hash: " drep_id
        cert_flags=(--drep-key-hash "$drep_id")
        ;;
    *)
        echo "Invalid choice." >&2
        exit 1
        ;;
esac

# ─── Build vote delegation certificate ─────────────────────────────────────────
cert_file="vote-deleg.cert"
echo "Generating delegation certificate..."
$CARDANO_CLI conway stake-address vote-delegation-certificate \
    --stake-verification-key-file stake.vkey \
    "${cert_flags[@]}" \
    --out-file "$cert_file"
check_command $? "Failed to create delegation certificate"

# ─── Build the transaction ─────────────────────────────────────────────────────
echo "Selecting UTxO for fee..."
# pick the first UTxO from payment.addr
tx_in=$(
  $CARDANO_CLI conway query utxo \
    --address "$(< payment.addr)" \
    $NETWORK \
    --out-file /dev/stdout \
  | jq -r 'keys[0]'
)
if [[ -z "$tx_in" ]]; then
    echo "No UTxO available to cover fees." >&2
    exit 1
fi

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

txid=$($CARDANO_CLI conway transaction txid --tx-file deleg.signed)
if [[ -n "$txid" ]]; then
    echo "✅ Delegation transaction submitted. TXID: $txid"
else
    echo "Error retrieving TXID" >&2
    exit 1
fi
