#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/config.sh"

LOGFILE="$HOME/.crd_cli-gui/tx.log"
mkdir -p "$(dirname "$LOGFILE")"

while true; do
  CHOICE=$(dialog --clear \
    --backtitle "Transactions" \
    --title "Transaction Menu" \
    --menu "Select an option:" 15 60 4 \
      1 "Send ADA" \
      2 "Lock Assets" \
      3 "Unlock Assets" \
      4 "Back to Main Menu" \
    2>&1 >/dev/tty)
  case "$CHOICE" in
    1)
      bash "$ROOT_DIR/wallet_transaction.sh" 2>&1 | tee -a "$LOGFILE"
      ;;
    2)
      bash "$ROOT_DIR/lock_assets.sh" 2>&1 | tee -a "$LOGFILE"
      ;;
    3)
      bash "$ROOT_DIR/unlock_assets.sh" 2>&1 | tee -a "$LOGFILE"
      ;;
    4)
      break
      ;;
  esac
done
