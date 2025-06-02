#!/bin/bash

SELECT_UTXO="./select-utxo.sh"

# Import modules
source "$SELECT_UTXO"


# Function to generate dRep keys
generate_drep_keys() {
  cardano-cli conway governance drep key-gen \
    --verification-key-file drep.vkey \
    --signing-key-file drep.skey
}


# Function to download dRep metadata file
download_drep_metadata() {
  wget -q https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0119/examples/drep.jsonld
}

# Function to calculate dRep metadata hash
calculate_metadata_hash() {
  metadata_hash=$(cardano-cli conway governance drep metadata-hash \
    --drep-metadata-file drep.jsonld)
  echo $metadata_hash
}

# Function to register dRep
register_drep() {
  # Get the metadata hash
  metadata_hash=$(calculate_metadata_hash)
  
  cardano-cli conway governance drep registration-certificate \
    --drep-verification-key-file drep.vkey \
    --key-reg-deposit-amt 500000000 \
    --drep-metadata-url https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0119/examples/drep.jsonld \
    --drep-metadata-hash $metadata_hash \
    --out-file drep-reg.cert
}

# Function to build dRep registration transaction
build_drep_tx() {
  select_utxo "payment"
  tx_in="$SELECTED_UTXO"


  
  cardano-cli conway transaction build \
    --tx-in "$tx_in" \
    --change-address $(< payment.addr) \
    --certificate-file drep-reg.cert  \
    --testnet-magic 2 \
    --witness-override 2 \
    --out-file tx.raw
}

# Function to sign and submit dRep registration transaction
sign_and_submit_drep_tx() {
  cardano-cli conway transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file drep.skey \
    --out-file tx.signed
  echo "txhash :"
  cardano-cli conway transaction submit \
    --tx-file tx.signed \
    --testnet-magic 2
}

export_drepid (){
   cardano-cli conway governance drep id \
  --drep-verification-key-file drep.vkey \
  --output-format hex > drep.id
}

# Function to query governance state
query_governance_state() {
  cardano-cli conway query gov-state --testnet-magic 2 > gov-state.json

  cat gov-state.json
}

# Function to create a vote
create_vote() {
  echo "Enter the governance-action-tx-id (tx_in):"
  read -r tx_in

  echo "Enter the governance-action-index:"
  read -r index

  if [ -z "$tx_in" ] || [ -z "$index" ]; then
    echo "Both tx_in and index are required."
    return 1
  fi

  # Gán giá trị cho biến toàn cục
  vote_file="${tx_in}-${index}.vote"

  cardano-cli conway governance vote create \
    --yes \
    --governance-action-tx-id "$tx_in" \
    --governance-action-index "$index" \
    --drep-verification-key-file drep.vkey \
    --out-file "$vote_file"

  return 0
}




# Function to build and submit vote transaction
build_and_submit_vote_tx() {
  if [ -z "$vote_file" ]; then
    echo "Error: vote_file is not set."
    return 1
  fi

  cardano-cli conway transaction build \
    --tx-in "$(cardano-cli query utxo --address $(< payment.addr) --testnet-magic 2 --output-json | jq -r 'keys[0]')" \
    --change-address $(< payment.addr) \
    --vote-file "$vote_file" \
    --witness-override 2 \
    --out-file vote-tx.raw \
    --testnet-magic 2

  cardano-cli conway transaction sign --tx-body-file vote-tx.raw \
    --signing-key-file drep.skey \
    --signing-key-file payment.skey \
    --out-file vote-tx.signed \
    --testnet-magic 2

  cardano-cli conway transaction submit --tx-file vote-tx.signed --testnet-magic 2
}



# Main menu
main_menu() {
  clear
  echo "Choose an option:"
  echo "1. Register dRep (Decentralized Representative)"
  echo "2. Cast a Vote for Governance Action"
  echo "3. Delegate Vote to a Drep"
  echo "4. Exit"
  read -p "Enter your choice (1 or 2): " choice

  case $choice in
    1)
      echo "Generating dRep keys and preparing dRep registration..."
      generate_drep_keys
      download_drep_metadata
      calculate_metadata_hash
      register_drep
      build_drep_tx
      sign_and_submit_drep_tx
      export_drepid
      echo "dRep registration has been successfully completed. dRep is now registered on the Cardano blockchain."
      
      ;;
    2)
      echo "Casting Vote for Governance Action..."
      query_governance_state
      create_vote
      if [ $? -eq 0 ]; then
        build_and_submit_vote_tx
        echo "Vote has been successfully cast for governance action!"
      else
        echo "Failed to create vote file. Please ensure the governance action details are correct."
      fi

      ;;
    3)
      ./delegate_to_drep.sh
      ;;
    4)
      echo "Exiting....."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please select 1 or 2."
      ;;
  esac
}

# Run the main menu
main_menu

