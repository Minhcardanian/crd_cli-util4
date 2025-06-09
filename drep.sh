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

SELECT_UTXO="./select-utxo.sh"

# Import modules
source "$SELECT_UTXO"


# Function to generate dRep keys
generate_drep_keys() {
  $CARDANO_CLI conway governance drep key-gen \
    --verification-key-file drep.vkey \
    --signing-key-file drep.skey
}


# Function to download dRep metadata file
download_drep_metadata() {
  wget -q https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0119/examples/drep.jsonld
}

# Function to calculate dRep metadata hash
calculate_metadata_hash() {
  metadata_hash=$($CARDANO_CLI conway governance drep metadata-hash \
    --drep-metadata-file drep.jsonld)
  echo $metadata_hash
}

# Function to register dRep
register_drep() {
  # Get the metadata hash
  metadata_hash=$(calculate_metadata_hash)
  
  $CARDANO_CLI conway governance drep registration-certificate \
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


  
  $CARDANO_CLI conway transaction build \
    --tx-in "$tx_in" \
    --change-address "$(< payment.addr)" \
    --certificate-file drep-reg.cert  \
    $NETWORK \
    --witness-override 2 \
    --out-file tx.raw
}

# Function to sign and submit dRep registration transaction
sign_and_submit_drep_tx() {
  sign_tx --tx-body-file tx.raw \
          --signing-key-file payment.skey \
          --signing-key-file drep.skey \
          --out-file tx.signed
  echo "txhash :"
  submit_tx --tx-file tx.signed
}

export_drepid (){
   $CARDANO_CLI conway governance drep id \
  --drep-verification-key-file drep.vkey \
  --output-format hex > drep.id
}

# Function to query governance state
query_governance_state() {
  $CARDANO_CLI conway query gov-state $NETWORK > gov-state.json

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

  $CARDANO_CLI conway governance vote create \
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

  $CARDANO_CLI conway transaction build \
    --tx-in "$($CARDANO_CLI query utxo --address "$(< payment.addr)" $NETWORK --output-json | jq -r 'keys[0]')" \
    --change-address "$(< payment.addr)" \
    --vote-file "$vote_file" \
    --witness-override 2 \
    --out-file vote-tx.raw \
    $NETWORK

  sign_tx --tx-body-file vote-tx.raw \
          --signing-key-file drep.skey \
          --signing-key-file payment.skey \
          --out-file vote-tx.signed

  submit_tx --tx-file vote-tx.signed
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

