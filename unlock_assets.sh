#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.sh"
LIB="$SCRIPT_DIR/lib.sh"
UTILS="$SCRIPT_DIR/file_utils.sh"

for f in "$CONFIG" "$LIB" "$UTILS"; do
    [[ -f "$f" ]] || { echo "Required file not found: $f" >&2; exit 1; }
    source "$f"
done

# ─── Main unlock function ──────────────────────────────────────────────────────
unlock_asset() {
    # 1) Select Plutus script and derive script.addr
    echo ">> Select Plutus script file"
    select_file "plutus_scripts" "plutus"
    script_plutus="$selected_file"

    echo ">> Building contract address"
    run_plutus_script "$script_plutus" script.addr
    check_command $? "Failed to build script.addr"

    # 2) Pick the UTxO at script address to unlock
    echo ">> Select UTxO at script address"
    select_utxo "script"
    tx_in="$SELECTED_UTXO"

    # 3) Pick collateral from payment address
    echo ">> Select collateral UTxO at payment address"
    select_utxo "payment"
    tx_collateral="$SELECTED_UTXO"

    # 4) Select redeemer JSON
    echo ">> Select redeemer JSON file"
    select_file "redeemers" "json"
    redeemer_file="$selected_file"

    # 5) Build
    echo ">> Building unlock transaction"
    build_tx \
        --tx-in "$tx_in" \
        --tx-in-collateral "$tx_collateral" \
        --tx-in-script-file "$script_plutus" \
        --tx-in-inline-datum-present \
        --tx-in-redeemer-file "$redeemer_file" \
        --change-address "$(<payment.addr)" \
        --out-file unlock.tx
    check_command $? "Failed to build unlock.tx"

    # 6) Sign
    echo ">> Signing transaction"
    sign_tx \
        --tx-file unlock.tx \
        --signing-key-file "$SIGNING_KEY_FILE" \
        --out-file unlock.tx.signed
    check_command $? "Failed to sign unlock.tx"

    # 7) Submit
    echo ">> Submitting transaction"
    submit_tx --tx-file unlock.tx.signed
    check_command $? "Failed to submit unlock.tx.signed"

    # 8) Report TXID
    txid=$($CARDANO_CLI conway transaction txid --tx-file unlock.tx.signed)
    if [[ -n "$txid" ]]; then
        echo "✅ Unlock transaction submitted. TXID: $txid"
    else
        echo "Error: couldn’t retrieve TXID" >&2
        exit 1
    fi
}

# ─── Invoke and exit ───────────────────────────────────────────────────────────
unlock_asset
