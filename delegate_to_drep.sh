#!/bin/bash

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

# Execute the corresponding cardano-cli command based on the user's choice
case $choice in
  1) 
    echo "Delegating vote with Always Abstain..."
    cardano-cli conway stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --always-abstain \
      --out-file vote-deleg.cert
    ;;
  2) 
    echo "Delegating vote with No Confidence..."
    cardano-cli conway stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --always-no-confidence \
      --out-file vote-deleg.cert
    ;;
  3) 
    echo "Delegating vote to DRep with ID: $drep_id..."
    cardano-cli conway stake-address vote-delegation-certificate \
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
cardano-cli conway transaction build \
  --tx-in $(cardano-cli query utxo --address $(< payment.addr) --testnet-magic 2 --out-file /dev/stdout | jq -r 'keys[0]') \
  --change-address $(< payment.addr) \
  --certificate-file vote-deleg.cert \
  --witness-override 2 \
  --out-file tx.raw \
  --testnet-magic 2

echo "Signing transaction..."
cardano-cli conway transaction sign \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --signing-key-file stake.skey \
  --out-file tx.signed

echo "Submitting transaction..."
cardano-cli conway transaction submit \
  --tx-file tx.signed \
  --testnet-magic 2

echo "Vote delegation transaction completed."
