
#!/bin/bash
source "$(dirname "$0")/config.sh"

UTXO_FILE="utxo.json"

# Function to select UTXO
select_utxo() {
    local input_type="$1"  # Input parameter: "payment" or "script"

    if [[ "$input_type" == "payment" ]]; then
        # Query UTXO from the payment address
        $CARDANO_CLI conway query utxo \
            --address "$(cat payment.addr)" \
            $NETWORK \
            --output-json > "$UTXO_FILE"
        echo "UTXO list from payment address:"

    elif [[ "$input_type" == "script" ]]; then
        # Query UTXO from the script address
        $CARDANO_CLI conway query utxo \
            --address "$(cat script.addr)" \
            $NETWORK \
            --output-json > "$UTXO_FILE"
        echo "UTXO list from script address:"

    else
        echo "Invalid input type. Please select 'payment' or 'script'."
        exit 1
    fi

    # Sort UTXO list by txHash and txIndex (descending order)
    sorted_utxos=$(jq -r 'to_entries | sort_by(.key) | reverse | .[] | "\(.key) : \(.value.value.lovelace)"' "$UTXO_FILE")

    # Display sorted UTXO list
    echo "Sorted UTXO list by txHash (descending):"
    echo "$sorted_utxos" | nl -w2 -s'. '

    # Ask the user to select a UTXO
    read -p "Enter the number corresponding to the UTXO you want to use: " selected_index
    SELECTED_UTXO=$(echo "$sorted_utxos" | sed -n "${selected_index}p" | awk '{print $1}')
    if [[ -z "$SELECTED_UTXO" ]]; then
        echo "Invalid selection. Please try again."
        exit 1
    fi

    echo "You have selected UTXO: $SELECTED_UTXO"
}

# Example usage of the function:
# To select a payment UTXO:
# select_utxo "payment"

# To select a script UTXO:
# select_utxo "script"
