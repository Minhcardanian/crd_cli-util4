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

# Ask for user input to select an option
clear
echo "Select a vote delegation option:"
echo "1. Always Abstain"
echo "2. No Confidence"
echo "3. Delegate to DRep"
echo "4. Exit"

read -p "Enter your choice (1/2/3): " choice

# Ask for the DRep ID if needed
if [[ "$choice" == "3" ]]; then
  read -p "Enter the DRep ID: " drep_id
fi

# Execute the corresponding $CARDANO_CLI command based on the user's choice
case $choice in
  1) 
    echo "Delegating vote with Always Abstain..."
    $CARDANO_CLI conway stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --always-abstain \
      --out-file vote-deleg.cert
    ;;
  2) 
    echo "Delegating vote with No Confidence..."
    $CARDANO_CLI conway stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --always-no-confidence \
      --out-file vote-deleg.cert
    ;;
  3) 
    echo "Delegating vote to DRep with ID: $drep_id..."
    $CARDANO_CLI conway stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --drep-key-hash "$drep_id" \
      --out-file vote-deleg.cert
    ;;

  4)
    echo "Exiting the program..." 
    exit 0
    ;;
  *)
    echo "Invalid choice. Please select 1, 2, or 3."
    exit 1
    ;;
esac

# Perform the transaction
echo "Building transaction..."
$CARDANO_CLI conway transaction build \
  --tx-in "$($CARDANO_CLI query utxo --address "$(< payment.addr)" $NETWORK --out-file /dev/stdout | jq -r 'keys[0]')" \
  --change-address "$(< payment.addr)" \
  --certificate-file vote-deleg.cert \
  --witness-override 2 \
  --out-file tx.raw \
  $NETWORK

echo "Signing transaction..."
sign_tx --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file stake.skey \
        --out-file tx.signed

echo "Submitting transaction..."
submit_tx --tx-file tx.signed

echo "Vote delegation transaction completed."
