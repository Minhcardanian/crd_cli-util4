#!/usr/bin/env bash
# Example: send ADA from the local wallet to a specified address
#
# Preconditions:
# 1. The files payment.addr and payment.skey exist and contain your wallet
#    address and signing key.
# 2. cardano-node is running and CARDANO_NODE_SOCKET_PATH points to the socket.
# 3. protocol.json is up to date.
#
# Usage: ./send-ada.sh <receiver-address> [amount-lovelace]
# Output: Transaction identifier on success.
# Verification: Query the receiver address UTxOs to confirm receipt.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib.sh"

RECEIVER_ADDR=${1:-}
AMOUNT=${2:-1000000}

if [[ -z "$RECEIVER_ADDR" ]]; then
  echo "Usage: $0 <receiver-address> [amount-lovelace]" >&2
  exit 1
fi

select_utxo "payment"

build_tx \
  --tx-in "$SELECTED_UTXO" \
  --tx-out "${RECEIVER_ADDR}+${AMOUNT}" \
  --change-address "$(cat payment.addr)" \
  --out-file send-ada.raw

sign_tx \
  --tx-body-file send-ada.raw \
  --signing-key-file payment.skey \
  --out-file send-ada.signed

submit_tx --tx-file send-ada.signed

TXID=$($CARDANO_CLI conway transaction txid --tx-file send-ada.signed)
echo "Transaction submitted. TxID: $TXID"
