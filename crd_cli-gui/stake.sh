#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/config.sh"

LOGFILE="$HOME/.crd_cli-gui/stake.log"
mkdir -p "$(dirname "$LOGFILE")"

while true; do
  CHOICE=$(dialog --clear \
    --backtitle "Stake & Delegation" \
    --title "Stake Menu" \
    --menu "Choose an operation:" 15 60 3 \
      1 "Delegate / Withdraw" \
      2 "Governance (dRep)" \
      3 "Back to Main Menu" \
    2>&1 >/dev/tty)
  case "$CHOICE" in
    1)
      bash "$ROOT_DIR/delegate.sh" 2>&1 | tee -a "$LOGFILE"
      ;;
    2)
      bash "$ROOT_DIR/drep.sh" 2>&1 | tee -a "$LOGFILE"
      ;;
    3)
      break
      ;;
  esac
done
