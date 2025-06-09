#!/usr/bin/env bash
source "$(dirname "$0")/config.sh"
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

# Configuration
SELECT_UTXO="./select-utxo.sh"
FILE_UTILS="./file_utils.sh"

# Import modules
source "$FILE_UTILS"
source "$SELECT_UTXO"

# Check if cardano-cli is installed
check_cardano_cli() {
    if ! command -v "$CARDANO_CLI" &> /dev/null; then
        echo "cardano-cli is not installed. Please install it first."
        exit 1
    fi
}

# Function to check UTXO
check_utxo() {
    select_file "$(dirname "$0")" "addr"
    local check_file="$selected_file"
    
    echo "Querying UTXO for the address in file: $check_file"
    $CARDANO_CLI conway query utxo \
        --address "$(cat "$check_file")" \
        $NETWORK
}

# Function to check transaction hash
check_txhash() {
    read -p "Please enter the transaction hash (tx hash): " TX_HASH

    if [ -z "$TX_HASH" ]; then
        echo "You need to provide a transaction hash."
        return
    fi

    echo "Checking transaction details for hash: $TX_HASH"
    local TX_DETAILS
    TX_DETAILS=$($CARDANO_CLI query utxo \
        --tx-in "$TX_HASH" \
        $NETWORK 2>&1)

    if echo "$TX_DETAILS" | grep -q "Error"; then
        echo "Transaction does not exist or cannot be queried."
    else
        echo "$TX_DETAILS"
    fi
}

# Function to display the main menu
show_menu() {
    echo "------------------------------------------------------------"
    echo "Please choose an option:"
    echo "1. Check UTXO"
    echo "2. Check TX Hash"
    echo "3. Exit"
    echo "------------------------------------------------------------"
}

# Function to process user choices
process_choice() {
    read -p "Enter your choice (1/2/3): " choice
    case "$choice" in
        1) check_utxo ;;
        2) check_txhash ;;
        3) echo "Exiting program..."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Main function to run the program
main() {
    check_cardano_cli
    while true; do
        show_menu
        process_choice
        echo "Press ESC to return to the main menu or any other key to exit."
        read -s -n 1 key
        [[ $key != $'\e' ]] && exit 0
    done
}

# Start the program
main
