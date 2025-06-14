#!/bin/bash
source "$(dirname "$0")/config.sh"
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"

if [[ ! -f "$CONFIG_FILE" || ! -f "$LIB_FILE" ]]; then
  echo "Required config.sh or lib.sh not found" >&2
  exit 1
fi

source "$CONFIG_FILE"
source "$LIB_FILE"

# Path to wallet generation module
WALLET_GENERATE="$SCRIPT_DIR/wallet-generate.sh"
if [[ ! -f "$WALLET_GENERATE" ]]; then
    echo "wallet-generate.sh not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Check if the wallet exists
check_and_generate_wallet() {
    if [[ ! -f "payment.addr" ]]; then
        echo "Wallet not found. Calling wallet generation module..."
        bash "$WALLET_GENERATE"
    else
        echo "Wallet already exists."
    fi
}

# Function to perform the transaction
perform_transaction() {
    select_utxo "payment" || return 1
    if [[ -z "${SELECTED_UTXO:-}" ]]; then
        echo "No UTXO selected. Exiting." >&2
        return 1
    fi
    echo "Using UTXO: $SELECTED_UTXO for the transaction."
    local tx_in="$SELECTED_UTXO"

    read -p "Enter the amount (tx-amount): " tx_amount
    read -p "Enter the recipient address (tx-out): " tx_out

<<<<<<< HEAD
    # Build the transaction
    echo "Building the transaction..."
    if $CARDANO_CLI conway transaction build \
        $NETWORK \
        --tx-in "$tx_in" \
        --tx-out "$tx_out+$tx_mount" \
        --change-address "$(cat payment.addr)" \
        --out-file simple-tx.raw; then
        echo "Transaction successfully built."
    else
        echo "Error building the transaction."
        exit 1
    fi

    # Sign the transaction
    echo "Signing the transaction..."
    if $CARDANO_CLI conway transaction sign \
        --signing-key-file payment.skey \
        $NETWORK \
        --tx-body-file simple-tx.raw \
        --out-file simple-tx.signed; then
        echo "Transaction successfully signed."
    else
        echo "Error signing the transaction."
        exit 1
    fi

    # Submit the transaction
    echo "Submitting the transaction..."
    if $CARDANO_CLI conway transaction submit \
        --tx-file simple-tx.signed \
        $NETWORK > /dev/null 2>&1; then
        echo "Transaction successfully submitted."
    else
        echo "Error submitting the transaction."
        exit 1
    fi
=======
    build_tx --tx-in "$tx_in" \
             --tx-out "$tx_out+$tx_amount" \
             --change-address "$(cat payment.addr)" \
             --out-file simple-tx.raw || return 1

    sign_tx --signing-key-file payment.skey \
            --tx-body-file simple-tx.raw \
            --out-file simple-tx.signed || return 1

    submit_tx --tx-file simple-tx.signed >/dev/null 2>&1 || return 1
>>>>>>> feature/config-centralization

    echo "Retrieving transaction ID..."
<<<<<<< HEAD
    if txid=$($CARDANO_CLI conway transaction txid --tx-file simple-tx.signed); then
        echo "Transaction ID (txid): $txid"
    else
        echo "Error retrieving transaction ID."
        exit 1
    fi
=======
    txid=$($CARDANO_CLI conway transaction txid --tx-file simple-tx.signed)
    [[ -n "$txid" ]] && echo "Transaction ID (txid): $txid"
>>>>>>> feature/config-centralization
}

# Main function
main() {
    while true; do
        echo "--------------------------------------------------------"
        echo "Cardano Transaction Manager"
        echo "1. Check and generate wallet"
        echo "2. Perform a transaction"
        echo "3. Exit"
        read -p "Choose an option (1/2/3): " choice

        case $choice in
            1)
                check_and_generate_wallet
                ;;
            2)
                perform_transaction
                ;;
            3)
                echo "Exiting program..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        echo "Press ESC to return to the main menu or any other key to exit."
        read -s -n 1 key
        if [[ $key != $'\e' ]]; then
            echo "Exiting..."
            exit 0
        fi
    done
}

# Run the program
main
