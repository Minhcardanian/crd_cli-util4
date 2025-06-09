#!/bin/bash
source "$(dirname "$0")/config.sh"

# Function to execute a script based on user choice
execute_choice() {
    local script_name=$1
    if [[ -x $script_name ]]; then
        echo "Executing $script_name..."
        ./$script_name
    else
        echo "Error: Script $script_name not found or not executable."
    fi
    sleep 2
}

delete_wallet (){
    find . -maxdepth 1 -type f ! -name "*.sh" -exec rm -f {} +



}

# Main menu loop
while true; do
    clear
    echo "--------------------------------------------------------"
    echo "Welcome to the Cardano Asset Management System"
    echo "Please choose an option:"
    echo "1. Create Wallet"
    echo "2. Create Transaction"
    echo "3. Delegate"
    echo "4. Lock Assets to Smart Contract"
    echo "5. Unlock Assets"
    echo "6. Run Node"
    echo "7. Check UTXO"
    echo "8. Governance"
    echo "9. Delete Wallet"
    echo "10. Exit"
    echo -n "Enter your choice (1-8): "

    # Read user input for the chosen option
    read -r choice

    case $choice in
        1) execute_choice "wallet-generate.sh" ;;
        2) execute_choice "wallet_transaction.sh" ;;
        3) execute_choice "delegate.sh" ;;
        4) execute_choice "lock_assets.sh" ;;
        5) execute_choice "unlock_assets.sh" ;;
        6) execute_choice "run-node.sh" ;;
        7) execute_choice "check.sh" ;;
        8) execute_choice "drep.sh" ;;
        9) delete_wallet ;;
        10)
            echo "Exiting the program..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose a valid option between 1 and 8."
            sleep 2
            ;;
    esac
done
