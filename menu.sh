#!/usr/bin/env bash
set -euo pipefail

# Simple whiptail-based UI wrapper
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

build_tx_flow() {
    whiptail --msgbox "Building transaction (placeholder)" 8 40
}

sign_tx_flow() {
    whiptail --msgbox "Signing transaction (placeholder)" 8 40
}

submit_tx_flow() {
    whiptail --msgbox "Submitting transaction (placeholder)" 8 40
}

plutus_menu() {
    whiptail --msgbox "Plutus utilities (placeholder)" 8 40
}

while true; do
    CHOICE=$(whiptail --backtitle "crd_cli-util4" --title "Main Menu" \
        --menu "Select action:" 15 60 6 \
        1 "Generate Keys" \
        2 "Build Transaction" \
        3 "Sign Transaction" \
        4 "Submit Transaction" \
        5 "Plutus Utilities" \
        6 "Exit" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && break
    clear
    case "$CHOICE" in
        1)
            NAME=$(whiptail --inputbox "Wallet name:" 8 40 3>&1 1>&2 2>&3)
            [ -n "$NAME" ] && generate_keys "$NAME"
            ;;
        2)
            build_tx_flow
            ;;
        3)
            sign_tx_flow
            ;;
        4)
            submit_tx_flow
            ;;
        5)
            plutus_menu
            ;;
        6)
            break
            ;;
    esac
    read -p "Press ENTER to continue..."
    clear
done
