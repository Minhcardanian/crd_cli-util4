#!/usr/bin/env bash
set -euo pipefail

# Simple dialog-based UI wrapper
export DIALOGRC="$(pwd)/.dialogrc"
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

# ────────────────────────────────────────────────────────────────────
# BEGIN dialog-based menu
CHOICE_TMP="$(mktemp)"
dialog \
  --clear \
  --backtitle "" \
  --title "crd_cli-util4" \
  --no-shadow \
  --colors \
  --menu "\Z1Select action:\Zn" 10 50 6 \
    1 "Generate Keys" \
    2 "Check UTxO" \
    3 "Send ADA" \
    4 "Delegate Stake" \
    5 "Register/Update DRep" \
    6 "Lock Assets" \
    7 "Unlock Assets" \
    8 "Exit" \
  2> "$CHOICE_TMP"

choice=$(<"$CHOICE_TMP")
rm "$CHOICE_TMP"
# END dialog-based menu
# ────────────────────────────────────────────────────────────────────

case $choice in
  1) generate_keys ;;
  2) check_utxo    ;;
  3) send_ada      ;;
  4) delegate_stake;;
  5) register_drep ;;
  6) lock_assets   ;;
  7) unlock_assets ;;
  8) exit 0        ;;
  *) echo "Invalid choice" >&2; exit 1 ;;
esac
