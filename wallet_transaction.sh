#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"
UTILS_FILE="$SCRIPT_DIR/file_utils.sh"
WALLET_GEN="$SCRIPT_DIR/wallet-generate.sh"

for f in "$CONFIG_FILE" "$LIB_FILE" "$UTILS_FILE"; do
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

# ─── Ensure wallet exists or generate it ───────────────────────────────────────
ensure_wallet() {
  if [[ ! -f "${PAYMENT_ADDR_FILE}" ]]; then
    echo "No wallet found; generating now..."
    bash "$WALLET_GEN"
    check_command $? "Wallet generation failed"
  else
    echo "Wallet already exists: ${PAYMENT_ADDR_FILE}"
  fi
}

# ─── Perform a simple send transaction ─────────────────────────────────────────
perform_transaction() {
  # 1) Pick UTxO
  select_utxo "payment"
  check_command $? "UTxO selection failed"
  tx_in="$SELECTED_UTXO"

  # 2) Get amount and recipient
  read -rp "Enter amount to send (lovelace): " tx_amount
  if ! [[ "$tx_amount" =~ ^[0-9]+$ ]]; then
    echo "Invalid amount" >&2
    exit 1
  fi
  read -rp "Enter recipient address: " tx_out

  # 3) Build
  echo "Building transaction..."
  build_tx \
    --tx-in "$tx_in" \
    --tx-out "${tx_out}+${tx_amount}" \
    --change-address "$(< "$PAYMENT_ADDR_FILE")" \
    --out-file tx.raw
  check_command $? "Failed to build transaction"

  # 4) Sign
  echo "Signing transaction..."
  sign_tx \
    --tx-body-file tx.raw \
    --signing-key-file "$SIGNING_KEY_FILE" \
    --out-file tx.signed
  check_command $? "Failed to sign transaction"

  # 5) Submit
  echo "Submitting transaction..."
  submit_tx --tx-file tx.signed
  check_command $? "Failed to submit transaction"

  # 6) Report
  txid=$($CARDANO_CLI conway transaction txid --tx-file tx.signed)
  if [[ -n "$txid" ]]; then
    echo "✅ Transaction submitted! TXID: $txid"
  else
    echo "Error: Could not retrieve TXID" >&2
    exit 1
  fi
}

# ─── Main ──────────────────────────────────────────────────────────────────────
ensure_wallet
perform_transaction
