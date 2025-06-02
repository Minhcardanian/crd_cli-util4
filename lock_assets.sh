
#!/bin/bash

SELECT_UTXO="./select-utxo.sh"
FILE_UTILS="./file_utils.sh"

# Import modules
source "$FILE_UTILS"
source "$SELECT_UTXO"

TESTNET_MAGIC=2
PAYMENT_ADDR_FILE="payment.addr"
SIGNING_KEY_FILE="payment.skey"

# Helper function to check command execution
check_command() {
    if [[ $1 -ne 0 ]]; then
        echo "Error: $2"
        exit 1
    fi
}

# Lock asset transaction to a smart contract
lock_asset() {
    echo ">> Selecting UTXO from wallet to lock asset into the smart contract..."
    select_utxo "payment"
    if [[ -z "$SELECTED_UTXO" ]]; then
        echo "Error: No UTXO selected. Exiting."
        return
    fi
    echo "Selected UTXO: $SELECTED_UTXO"
    tx_in="$SELECTED_UTXO"

    read -p "Enter transaction amount (in lovelace): " tx_amount
    if ! [[ "$tx_amount" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid amount. Exiting."
        return
    fi

    echo ">> Selecting Plutus script file..."
    select_file "plutus_scripts" "plutus"
    check_command $? "Failed to select Plutus script file."
    script_plutus="$selected_file"

    echo ">> Selecting datum file..."
    select_file "datum" "json"
    check_command $? "Failed to select datum file."
    datum_file="$selected_file"

    echo ">> Building smart contract address..."
    cardano-cli address build \
        --payment-script-file "$script_plutus" \
        --out-file script.addr \
        --testnet-magic "$TESTNET_MAGIC"
    check_command $? "Failed to build smart contract address."

    echo ">> Building transaction..."
    cardano-cli conway transaction build \
        --tx-in "$tx_in" \
        --tx-out "$(cat script.addr)+$tx_amount" \
        --tx-out-inline-datum-file "$datum_file" \
        --change-address "$(cat "$PAYMENT_ADDR_FILE")" \
        --testnet-magic "$TESTNET_MAGIC" \
        --out-file lock.tx
    check_command $? "Failed to build transaction."

    echo ">> Signing transaction..."
    cardano-cli conway transaction sign \
        --tx-file lock.tx \
        --signing-key-file "$SIGNING_KEY_FILE" \
        --out-file lock.tx.signed
    check_command $? "Failed to sign transaction."

    echo ">> Submitting transaction..."
    cardano-cli conway transaction submit \
        --testnet-magic "$TESTNET_MAGIC" \
        --tx-file lock.tx.signed
    check_command $? "Failed to submit transaction."

    txid=$(cardano-cli conway transaction txid --tx-file lock.tx.signed)
    if [[ -n "$txid" ]]; then
        echo "Transaction successful!"
        echo "Transaction hash (TXID): $txid"
    else
        echo "Error: Failed to retrieve transaction hash."
        exit 1
    fi
}

# Main menu
main() {
    while true; do
        echo "--------------------------------------------------------"
        echo "Cardano Asset Locking"
        echo "1. Lock asset to smart contract"
        echo "2. Exit"
        read -p "Choose an option (1/2): " choice

        case $choice in
            1) lock_asset ;;
            2) echo "Exiting program..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac

        echo "Press ESC to return to the main menu or any other key to exit."
        read -s -n 1 key
        [[ $key != $'\e' ]] && { echo "Exiting..."; exit 0; }
    done
}

# Run the program
main
