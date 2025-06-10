#!/usr/bin/env bash
set -euo pipefail

# Library of helper functions for Cardano CLI workflows
# Requires config.sh to be sourced before using these functions.

# Select a UTXO from either a payment or script address.
# Usage: select_utxo <payment|script>
select_utxo() {
    local input_type="${1:-payment}"
    local utxo_file="utxo.json"

    if [[ "$input_type" == "payment" ]]; then
        $CARDANO_CLI conway query utxo \
            --address "$(cat payment.addr)" \
            $NETWORK \
            --output-json > "$utxo_file"
        echo "UTXO list from payment address:"
    elif [[ "$input_type" == "script" ]]; then
        $CARDANO_CLI conway query utxo \
            --address "$(cat script.addr)" \
            $NETWORK \
            --output-json > "$utxo_file"
        echo "UTXO list from script address:"
    else
        echo "Invalid input type. Use 'payment' or 'script'." >&2
        return 1
    fi

    local sorted_utxos selected_index
    sorted_utxos=$(jq -r 'to_entries | sort_by(.key) | reverse | .[] | "\(.key): \(.value.value.lovelace)"' "$utxo_file")
    echo "Sorted UTXO list by txHash (descending):"
    echo "$sorted_utxos" | nl -w2 -s'. '

    read -p "Enter the number corresponding to the UTXO you want to use: " selected_index
    SELECTED_UTXO=$(echo "$sorted_utxos" | sed -n "${selected_index}p" | awk '{print $1}')
    if [[ -z "$SELECTED_UTXO" ]]; then
        echo "Invalid selection." >&2
        return 1
    fi
    echo "Selected UTXO: $SELECTED_UTXO"
}

# Calculate minimum fee for a transaction
# Usage: calculate_fee <tx_body_file> <tx_in_count> <tx_out_count> <witness_count>
calculate_fee() {
    local body_file=$1
    local in_count=$2
    local out_count=$3
    local witness_count=$4

    echo "Calculating minimum fee..."
    $CARDANO_CLI conway transaction calculate-min-fee \
        --tx-body-file "$body_file" \
        --tx-in-count "$in_count" \
        --tx-out-count "$out_count" \
        --witness-count "$witness_count" \
        $NETWORK \
        --protocol-params-file "$PROTOCOL_PARAMS"
}

# Build a raw transaction
# Usage: build_tx [cardano-cli build args] --out-file <file>
build_tx() {
    echo "Building transaction..."
    $CARDANO_CLI conway transaction build "$@" $NETWORK
}

# Sign a transaction
# Usage: sign_tx --tx-body-file <file> --out-file <signed-file> [--signing-key-file ...]
sign_tx() {
    echo "Signing transaction..."
    $CARDANO_CLI conway transaction sign "$@" $NETWORK
}

# Submit a signed transaction
# Usage: submit_tx --tx-file <signed-file>
submit_tx() {
    echo "Submitting transaction..."
    $CARDANO_CLI conway transaction submit "$@" $NETWORK
}

# Simple helper to derive a script address from a Plutus script file
# Usage: run_plutus_script <script.plutus> <out.addr>
run_plutus_script() {
    local script_file=$1
    local out_file=${2:-script.addr}
    echo "Building script address from $script_file..."
    $CARDANO_CLI address build --payment-script-file "$script_file" --out-file "$out_file" $NETWORK
}
