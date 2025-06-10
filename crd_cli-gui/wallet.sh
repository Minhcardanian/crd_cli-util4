#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

LOGFILE="$HOME/.crd_cli-gui/wallet.log"
mkdir -p "$(dirname "$LOGFILE")"

while true; do
  CHOICE=$(dialog --clear \
    --backtitle "Wallet Management" \
    --title "Wallet Menu" \
    --menu "Choose an operation:" 15 60 5 \
      1 "Create New Wallet" \
      2 "View Wallet Address" \
      3 "Reveal Seed Phrase" \
      4 "View Wallet Logs" \
      5 "Back to Main Menu" \
    2>&1 >/dev/tty)
  case "$CHOICE" in
    1) create_wallet | tee -a "$LOGFILE" ;;
    2) show_address  | tee -a "$LOGFILE" | dialog --msgbox "$(show_address)" 8 60 ;;
    3)
      PASS=$(dialog --insecure --passwordbox "Enter your wallet passphrase:" 8 60 2>&1 >/dev/tty)
      if verify_passphrase "$PASS"; then
        SEED=$(get_seed_phrase)
        dialog --title "Seed Phrase" --msgbox "$SEED" 12 60
      else
        dialog --msgbox "Invalid passphrase" 6 40
      fi
      ;;
    4)
      dialog --title "Wallet Logs" --textbox "$LOGFILE" 20 70
      ;;
    5) break ;;
  esac
done
