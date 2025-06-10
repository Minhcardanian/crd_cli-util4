#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

while true; do
  CHOICE=$(dialog --clear \
    --backtitle "crd_cli-gui" \
    --title "Main Menu" \
    --menu "Select action:" 15 60 5 \
      1 "Wallet Management" \
      2 "Transactions" \
      3 "Stake & Delegation" \
      4 "Node Control" \
      5 "Quit" \
    2>&1 >/dev/tty)
  case "$CHOICE" in
    1) bash "$SCRIPT_DIR/wallet.sh"   ;;
    2) bash "$SCRIPT_DIR/tx.sh"       ;;
    3) bash "$SCRIPT_DIR/stake.sh"    ;;
    4) bash "$SCRIPT_DIR/node.sh"     ;;
    5) clear; exit 0                  ;;
  esac
done
