#!/bin/bash
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

FILE_UTILS="./file_utils.sh"

# Import modules
source "$FILE_UTILS"

# Function to unlock asset
unlock_asset() {
    # Select .plutus script file
    echo "Select the .plutus script file to use for unlocking."
    select_file "plutus_scripts" "plutus"
    script_plutus=$selected_file

    # Build address with Plutus script
    if run_plutus_script "$script_plutus" script.addr; then
        echo "Smart contract address created: script.addr"
    else
        echo "Error building smart contract address."
        exit 1
    fi

    echo "Select UTXO from smart contract to unlock!"
    select_utxo "script"
    tx_in="$SELECTED_UTXO"
    
    if [[ -z "$tx_in" ]]; then
        echo "No UTXO selected for the smart contract. Exiting."
        return
    fi
    echo "Using UTXO: $tx_in for the unlock transaction"

    echo "Select UTXO from payment address to use as collateral for unlocking!"
    select_utxo "payment"
    tx_collateral="$SELECTED_UTXO"

    if [[ -z "$tx_collateral" ]]; then
        echo "No UTXO selected for collateral. Exiting."
        return
    fi
    echo "Using UTXO: $tx_collateral as collateral"

    # Select redeemer JSON file
    echo "Select the redeemer JSON file."
    select_file "redeemers" "json"
    redeemer_file=$selected_file

    if [[ -z "$redeemer_file" ]]; then
        echo "No redeemer file selected. Exiting."
        return
    fi
    echo "Using redeemer file: $redeemer_file"

    # Step 1: Build the transaction
    echo "Building unlock transaction..."
    if build_tx --tx-in "$tx_in" \
                --tx-in-collateral "$tx_collateral" \
                --tx-in-script-file "$script_plutus" \
                --tx-in-inline-datum-present \
                --tx-in-redeemer-file "$redeemer_file" \
                --change-address "$(< payment.addr)" \
                --out-file unlock.tx; then
        echo "Transaction built successfully."
    else
        echo "Error building the transaction."
        exit 1
    fi

    # Step 2: Sign the transaction
    echo "Signing the transaction..."
    if sign_tx --tx-body-file unlock.tx \
              --signing-key-file payment.skey \
              --out-file unlock.tx.signed; then
        echo "Transaction signed successfully."
    else
        echo "Error signing the transaction."
        exit 1
    fi

    # Step 3: Submit the transaction
    echo "Submitting the transaction..."
    if submit_tx --tx-file unlock.tx.signed; then
        echo "Transaction submitted successfully."
    else
        echo "Error submitting the transaction."
        exit 1
    fi

    # Step 4: Check the txid of the transaction
    echo "Checking the txid..."
    txid=$($CARDANO_CLI conway transaction txid --tx-file unlock.tx.signed)
    if [[ -n "$txid" ]]; then
        echo "Transaction hash (TXID): $txid"
    else
        echo "Error retrieving TXID."
        exit 1
    fi
}

# Main function with menu
main() {
    while true; do
        echo "--------------------------------------------------------"
        echo "Cardano Asset Unlocking"
        echo "1. Unlock asset from smart contract"
        echo "2. Exit"
        read -p "Choose an option (1/2): " choice

        case $choice in
            1)
                unlock_asset
                ;;
            2)
                echo "Exiting program..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        # Ask user to press ESC to return to main menu or any other key to exit
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
