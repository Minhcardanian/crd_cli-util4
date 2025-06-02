#!/bin/bash

# Path to wallet generation and UTXO selection modules
WALLET_GENERATE="./wallet-generate.sh"
SELECT_UTXO="./select-utxo.sh"

# Source the UTXO selection script
source "$SELECT_UTXO"

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
    # Source the UTXO selection module
    select_utxo "payment"

    # Use the selected UTXO
    if [[ -z "$SELECTED_UTXO" ]]; then
        echo "No UTXO selected. Exiting."
        return
    fi
    echo "Using UTXO: $SELECTED_UTXO for the transaction."
    tx_in="$SELECTED_UTXO"

    read -p "Enter the amount (tx-mount): " tx_mount
    read -p "Enter the recipient address (tx-out): " tx_out

    # Build the transaction
    echo "Building the transaction..."
    if cardano-cli conway transaction build \
        --testnet-magic 2 \
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
    if cardano-cli conway transaction sign \
        --signing-key-file payment.skey \
        --testnet-magic 2 \
        --tx-body-file simple-tx.raw \
        --out-file simple-tx.signed; then
        echo "Transaction successfully signed."
    else
        echo "Error signing the transaction."
        exit 1
    fi

    # Submit the transaction
    echo "Submitting the transaction..."
    if cardano-cli conway transaction submit \
        --tx-file simple-tx.signed \
        --testnet-magic 2 > /dev/null 2>&1; then
        echo "Transaction successfully submitted."
    else
        echo "Error submitting the transaction."
        exit 1
    fi

    # Retrieve txid
    echo "Retrieving transaction ID..."
    if txid=$(cardano-cli conway transaction txid --tx-file simple-tx.signed); then
        echo "Transaction ID (txid): $txid"
    else
        echo "Error retrieving transaction ID."
        exit 1
    fi
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
