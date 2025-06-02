
#!/bin/bash

# Check required tools before running
command -v cardano-address > /dev/null || { echo "Error: 'cardano-address' is not installed."; exit 1; }
command -v cardano-cli > /dev/null || { echo "Error: 'cardano-cli' is not installed."; exit 1; }

# Display menu options
while true; do
    echo "--------------------------------------------------------"
    echo "Please choose an option:"
    echo "1. Create a new wallet"
    echo "2. Restore wallet from 24-word recovery phrase"
    echo "3. Exit"
    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1)
            # Create new wallet
            echo "Creating a new wallet..."
            cardano-address recovery-phrase generate --size 24 > phrase.prv
            echo "Recovery phrase has been saved to 'phrase.prv'. Keep it safe!"
            ;;
        2)
            # Restore wallet from recovery phrase
            read -s -p "Enter recovery phrase (24 words separated by spaces): " phrase
            echo "$phrase" > phrase.prv
            echo "Recovery phrase has been saved to 'phrase.prv'."
            ;;
        3)
            echo "Exiting program..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            continue
            ;;
    esac

        # Create root key
    cardano-address key from-recovery-phrase Shelley < phrase.prv > root.prv

    # Create payment keys
    cardano-address key child 1852H/1815H/0H/0/0 < root.prv > payment.prv

    cardano-address key public --without-chain-code < payment.prv > payment.pub

    cardano-cli key convert-cardano-address-key --shelley-payment-key \
        --signing-key-file payment.prv \
        --out-file payment.skey

    cardano-cli key verification-key \
        --signing-key-file payment.skey \
        --verification-key-file payment.vkey



    cat root.prv | cardano-address key child 1852H/1815H/0H/2/0 > stake.prv

    cardano-cli key convert-cardano-address-key \
        --signing-key-file stake.prv \
        --shelley-stake-key \
        --out-file stake.skey

    cardano-cli key verification-key \
        --signing-key-file stake.skey \
        --verification-key-file Ext_ShelleyStake.vkey

    cardano-cli key non-extended-key \
        --extended-verification-key-file Ext_ShelleyStake.vkey \
        --verification-key-file stake.vkey

    
    rm Ext_ShelleyStake.vkey stake.prv




    cardano-cli address build \
        --payment-verification-key-file payment.vkey \
        --testnet-magic 2 \
        --stake-verification-key-file stake.vkey \
        --out-file payment.addr


    cardano-cli conway stake-address build \
        --stake-verification-key-file stake.vkey \
        --out-file stake.addr \
        --testnet-magic 2
        
    # Display UTXO information
    echo "Payment address created: $(cat payment.addr)"
    cardano-cli query utxo --address "$(cat payment.addr)" --testnet-magic 2

    echo "Program completed. The following important files have been created:"
    echo "- phrase.prv: Recovery phrase"
    echo "- payment.addr: Payment address"
    echo "- stake.addr: Stake address"
    echo "--------------------------------------------------------"

    echo "Press ESC to return to the main menu or any other key to exit."
    read -s -n 1 key
    if [[ $key == $'\e' ]]; then
        continue
    else
        exit 0
    fi
done
