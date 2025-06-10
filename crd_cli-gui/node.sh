#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/config.sh"

while true; do
  CHOICE=$(dialog --clear \
    --backtitle "Node Control" \
    --title "Node Menu" \
    --menu "Select action:" 10 50 3 \
      1 "Run Node" \
      2 "Stop Node" \
      3 "Back to Main Menu" \
    2>&1 >/dev/tty)
  case "$CHOICE" in
    1)
      bash "$ROOT_DIR/run-node.sh"
      ;;
    2)
      pkill -f "cardano-node.*--database-path $DB_PATH" && \
        dialog --msgbox "Node stopped" 6 40
      ;;
    3)
      break
      ;;
  esac
done
