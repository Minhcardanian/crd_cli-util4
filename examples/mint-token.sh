#!/usr/bin/env bash
# Example: mint a simple native token
#
# Preconditions:
# 1. payment.addr and payment.skey exist and have enough ADA.
# 2. policy.script and policy.skey describe the minting policy.
# 3. cardano-node running and protocol.json available.
#
# Usage: ./mint-token.sh <token-name> [amount]
# Output: Transaction identifier of the mint transaction.
# Verification: query the payment address UTxO to see minted tokens.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib.sh"

TOKEN_NAME=${1:-}
AMOUNT=${2:-1}
POLICY_SCRIPT="policy.script"
POLICY_SKEY="policy.skey"

if [[ -z "$TOKEN_NAME" ]]; then
  echo "Usage: $0 <token-name> [amount]" >&2
  exit 1
fi

POLICY_ID=$($CARDANO_CLI transaction policyid --script-file "$POLICY_SCRIPT")
select_utxo "payment"

build_tx \
  --tx-in "$SELECTED_UTXO" \
  --tx-out "$(cat payment.addr)+2000000" \
  --mint "${AMOUNT} ${POLICY_ID}.${TOKEN_NAME}" \
  --mint-script-file "$POLICY_SCRIPT" \
  --change-address "$(cat payment.addr)" \
  --out-file mint.raw

sign_tx \
  --tx-body-file mint.raw \
  --signing-key-file payment.skey \
  --signing-key-file "$POLICY_SKEY" \
  --out-file mint.signed

submit_tx --tx-file mint.signed

TXID=$($CARDANO_CLI conway transaction txid --tx-file mint.signed)
echo "Mint transaction submitted. TxID: $TXID"
