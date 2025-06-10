#!/usr/bin/env bash
# Example: spend ADA locked in a simple Plutus script
#
# Preconditions:
# 1. Funds have been locked to a script address using lock_assets.sh
# 2. payment.addr/payment.skey exist for collateral and change.
# 3. A redeemer JSON file is available.
#
# Usage: ./spend-script.sh <redeemer.json>
# Output: Transaction identifier of the spending transaction.
# Verification: query the script address UTxOs to ensure it was consumed.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib.sh"

REDEEMER_FILE=${1:-}
SCRIPT_FILE="../plutus_scripts/gift.plutus"

if [[ -z "$REDEEMER_FILE" ]]; then
  echo "Usage: $0 <redeemer.json>" >&2
  exit 1
fi

select_utxo "script"
TX_IN="$SELECTED_UTXO"

select_utxo "payment"
TX_COLLATERAL="$SELECTED_UTXO"

build_tx \
  --tx-in "$TX_IN" \
  --tx-in-script-file "$SCRIPT_FILE" \
  --tx-in-redeemer-file "$REDEEMER_FILE" \
  --tx-in-inline-datum-present \
  --tx-in-collateral "$TX_COLLATERAL" \
  --change-address "$(cat payment.addr)" \
  --out-file spend.raw

sign_tx \
  --tx-body-file spend.raw \
  --signing-key-file payment.skey \
  --out-file spend.signed

submit_tx --tx-file spend.signed

TXID=$($CARDANO_CLI conway transaction txid --tx-file spend.signed)
echo "Spend transaction submitted. TxID: $TXID"
