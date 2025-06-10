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

# Paths to important files
STAKE_VKEY="stake.vkey"
STAKE_SKEY="stake.skey"
PAYMENT_ADDR_FILE="payment.addr"
STAKE_ADDR_FILE="stake.addr"
PAYMENT_SKEY="payment.skey"
PAYMENT_ADDR=$(<payment.addr)
STAKE_ADDR=$(<stake.addr)
DEGREG_CERT="dereg.cert"

# External scripts
SELECT_UTXO="$SCRIPT_DIR/select-utxo.sh"
FILE_UTILS="$SCRIPT_DIR/file_utils.sh"

STAKE_KEY_REGISTERED=$($CARDANO_CLI query stake-address-info --address "$(cat $STAKE_ADDR_FILE)" $NETWORK | jq -r '.[0].stakeDelegation')

# Check if required external files exist
if [[ ! -f "$SELECT_UTXO" ]]; then
  echo "select-utxo.sh not found in $SCRIPT_DIR" >&2
  exit 1
fi

if [[ ! -f "$FILE_UTILS" ]]; then
  echo "file_utils.sh not found in $SCRIPT_DIR" >&2
  exit 1
fi

source "$SELECT_UTXO"
source "$FILE_UTILS"

# Function to select UTXO
select_valid_utxo() {
  echo "Selecting UTXO..."
  select_utxo "payment" # Assumes this is a function from select-utxo.sh
  if [[ -z "$SELECTED_UTXO" ]]; then
    echo "No UTXO selected. Please try again."
    return 1
  fi
  echo "Selected UTXO: $SELECTED_UTXO"
  return 0
}

# Function to select Pool ID
select_valid_poolid() {
  echo "Selecting Pool ID..."
  select_poolid # Assumes this is a function from file_utils.sh
  if [[ -z "$POOL_ID" ]]; then
    echo "No Pool ID selected. Please try again."
    return 1
  fi
  echo "Selected Pool ID: $POOL_ID"
  return 0
}

# Function to create stake certificates
create_stake_certificates() {
  local POOL_ID=$1
  local STAKE_CERT="stake-registration.cert"
  local DELEGATION_CERT="delegation.cert"

  if [[ "$STAKE_KEY_REGISTERED" == "null" ]]; then
    echo "Creating stake registration certificate..."
    $CARDANO_CLI conway stake-address registration-certificate \
      --stake-verification-key-file $STAKE_VKEY \
      --key-reg-deposit-amt 2000000 \
      --out-file $STAKE_CERT
  else
    echo "Stake key already registered. Skipping registration."
  fi

  echo "Creating delegation certificate for pool $POOL_ID..."
  $CARDANO_CLI conway stake-address stake-delegation-certificate \
    --stake-verification-key-file $STAKE_VKEY \
    --stake-pool-id $POOL_ID \
    --out-file $DELEGATION_CERT
}

# Function to create undelegation certificate
create_undelegation_certificate() {
  echo "Creating undelegation certificate..."
  $CARDANO_CLI conway stake-address deregistration-certificate \
    --stake-verification-key-file "$STAKE_VKEY" \
    --key-reg-deposit-amt 2000000 \
    --out-file "$DEGREG_CERT"
}

# Function to check for rewards
check_rewards() {
  REWARDS=$($CARDANO_CLI conway query stake-address-info --address "$STAKE_ADDR" $NETWORK | jq -r '.[0].rewardAccountBalance')
  if [[ "$REWARDS" == "null" || "$REWARDS" -eq 0 ]]; then
    echo "No rewards available to withdraw."
    return 1
  else
    echo "Rewards available: $REWARDS"
    return 0
  fi
}

submit_transaction() {
  local TX_RAW="tx.raw"
  local TX_SIGNED="tx.signed"
  local STAKE_CERT="stake-registration.cert"
  local DELEGATION_CERT="delegation.cert"
  local INCLUDE_STAKE_CERT=$1 # Optional argument to include stake registration certificate
  local INCLUDE_UNDELEGATION_CERT=$2 # Optional argument to include undelegation certificate

  echo "Building transaction..."
  $CARDANO_CLI conway transaction build \
    --tx-in "$SELECTED_UTXO" \
    --change-address "$(cat $PAYMENT_ADDR_FILE)" \
    --certificate-file $DELEGATION_CERT \
    --witness-override 2 \
    --out-file $TX_RAW \
    $NETWORK

  # Include stake registration certificate if needed
  if [[ "$INCLUDE_STAKE_CERT" == "true" ]]; then
    $CARDANO_CLI conway transaction build \
      --tx-in "$SELECTED_UTXO" \
      --change-address "$(cat $PAYMENT_ADDR_FILE)" \
      --certificate-file $STAKE_CERT \
      --certificate-file $DELEGATION_CERT \
      --witness-override 2 \
      --out-file $TX_RAW \
      $NETWORK
  fi

  # Include undelegation certificate if needed
  if [[ "$INCLUDE_UNDELEGATION_CERT" == "true" ]]; then
    $CARDANO_CLI conway transaction build \
      --tx-in "$SELECTED_UTXO" \
      --change-address "$(cat $PAYMENT_ADDR_FILE)" \
      --certificate-file $UNDELEGATION_CERT \
      --witness-override 2 \
      --out-file $TX_RAW \
      $NETWORK
  fi

  echo "Signing transaction..."
<<<<<<< HEAD
  $CARDANO_CLI conway transaction sign \
    --tx-body-file $TX_RAW \
    --signing-key-file $PAYMENT_SKEY \
    --signing-key-file $STAKE_SKEY \
    --out-file $TX_SIGNED

  echo "Submitting transaction..."
  $CARDANO_CLI conway transaction submit \
    --tx-file $TX_SIGNED \
    $NETWORK
=======
  sign_tx --tx-body-file "$TX_RAW" \
          --signing-key-file "$PAYMENT_SKEY" \
          --signing-key-file "$STAKE_SKEY" \
          --out-file "$TX_SIGNED"

  echo "Submitting transaction..."
  submit_tx --tx-file "$TX_SIGNED"
>>>>>>> feature/config-centralization
}

# Function to submit transaction for undelegation
submit_undelegation_transaction() {
  local TX_RAW="tx.raw"
  local TX_SIGNED="tx.signed"

  echo "Building transaction for undelegation..."

  if check_rewards; then
    # Case with rewards to withdraw
    $CARDANO_CLI conway transaction build \
      --tx-in "$SELECTED_UTXO" \
      --change-address "$PAYMENT_ADDR" \
      --withdrawal "$STAKE_ADDR+$REWARDS" \
      --certificate-file "$DEGREG_CERT" \
      --witness-override 2 \
      --out-file "$TX_RAW" \
      $NETWORK
  else
    # Case without rewards
    $CARDANO_CLI conway transaction build \
      --tx-in "$SELECTED_UTXO" \
      --change-address "$PAYMENT_ADDR" \
      --certificate-file "$DEGREG_CERT" \
      --witness-override 2 \
      --out-file "$TX_RAW" \
      $NETWORK
  fi

  echo "Signing transaction..."
<<<<<<< HEAD
  $CARDANO_CLI conway transaction sign \
    --tx-body-file "$TX_RAW" \
    --signing-key-file "$PAYMENT_SKEY" \
    --signing-key-file "$STAKE_SKEY" \
    --out-file "$TX_SIGNED"

  echo "Submitting transaction..."
  $CARDANO_CLI conway transaction submit \
    --tx-file "$TX_SIGNED" \
    $NETWORK
=======
  sign_tx --tx-body-file "$TX_RAW" \
          --signing-key-file "$PAYMENT_SKEY" \
          --signing-key-file "$STAKE_SKEY" \
          --out-file "$TX_SIGNED"

  echo "Submitting transaction..."
  submit_tx --tx-file "$TX_SIGNED"
>>>>>>> feature/config-centralization
}

# Function to check if the user is already delegated
is_delegated() {
  if [[ "$STAKE_KEY_REGISTERED" != "null" ]]; then
    return 0  # Already delegated
  else
    return 1  # Not delegated yet
  fi
}


# Function to withdraw rewards
withdraw_rewards() {
  echo "Withdrawing rewards..."
<<<<<<< HEAD
  $CARDANO_CLI conway transaction build \
    --tx-in "$SELECTED_UTXO" \
    --change-address "$PAYMENT_ADDR" \
    --withdrawal "$STAKE_ADDR" \
    --witness-override 2 \
    --out-file "withdrawal.raw" \
    $NETWORK

  $CARDANO_CLI conway transaction sign \
    --tx-body-file "withdrawal.raw" \
    --signing-key-file $PAYMENT_SKEY \
    --out-file "withdrawal.signed"

  $CARDANO_CLI conway transaction submit \
    --tx-file "withdrawal.signed" \
    $NETWORK
=======
  build_tx --tx-in "$SELECTED_UTXO" \
           --change-address "$PAYMENT_ADDR" \
           --withdrawal "${STAKE_ADDR}+${REWARDS}" \
           --witness-override 2 \
           --out-file "withdrawal.raw"

  sign_tx --tx-body-file "withdrawal.raw" \
          --signing-key-file "$PAYMENT_SKEY" \
          --out-file "withdrawal.signed"

  submit_tx --tx-file "withdrawal.signed"
>>>>>>> feature/config-centralization

  echo "Successfully withdrew rewards."
}
# Main menu
while true; do
  if is_delegated; then
    # If already delegated, show options to change delegation, undelegate, or exit
    echo "======================="
    echo "You Have Delegated to : $STAKE_KEY_REGISTERED"
    echo "1. Change delegation pool"
    echo "2. Undelegate & Withdraw all rewards"
    echo "3. Withdraw rewards to wallet"
    echo "4. Exit"
    echo "======================="
    read -rp "Enter your choice: " CHOICE

    case $CHOICE in
      1)
        # Change delegation pool
        if ! select_valid_poolid; then continue; fi
        if ! select_valid_utxo; then continue; fi
        create_stake_certificates "$POOL_ID"
        submit_transaction false # Do not include stake registration certificate
        echo "Successfully changed delegation to pool $POOL_ID"
        ;;
      2)
        # Undelegate
        echo "Undelegating..."
        if ! select_valid_utxo; then continue; fi
        create_undelegation_certificate
        submit_undelegation_transaction
        echo "Successfully undelegated from pool $STAKE_KEY_REGISTERED"
        ;;

      3)
        # Withdraw rewards
        if check_rewards; then
          withdraw_rewards
        fi
        ;;
      4)
        echo "Exiting the program."
        exit 0
        ;;
      *)
        echo "Invalid choice. Please try again."
        ;;
    esac
  else
    # If not delegated yet, show options to delegate or exit
    echo "======================="
    echo "You Have Not Yet Delegate!"
    echo "1. Delegate to a new pool"
    echo "2. Exit"
    echo "======================="
    read -rp "Enter your choice: " CHOICE

    case $CHOICE in
      1)
        # Delegate to a new pool
        if ! select_valid_poolid; then continue; fi
        if ! select_valid_utxo; then continue; fi
        create_stake_certificates "$POOL_ID"
        submit_transaction true # Include stake registration certificate
        echo "Successfully delegated to pool $POOL_ID!"
        ;;
      2)
        echo "Exiting the program."
        exit 0
        ;;
      *)
        echo "Invalid choice. Please try again."
        ;;
    esac
  fi
done
