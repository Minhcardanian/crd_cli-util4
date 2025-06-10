#!/usr/bin/env bash
set -euo pipefail

# ─── Base directory & theming ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RC="$SCRIPT_DIR/.dialogrc"
if [[ -f "$RC" ]]; then
  export DIALOGRC="$RC"
else
  unset DIALOGRC
  echo "[WARN] $RC not found; using default dialog theme" >&2
fi

# ─── Load configuration & shared functions ────────────────────────────────────
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

# ─── UI wrapper functions ─────────────────────────────────────────────────────
generate_keys()   { bash "$SCRIPT_DIR/wallet-generate.sh"; }
check_utxo()      { bash "$SCRIPT_DIR/check.sh"; }
send_ada()        { bash "$SCRIPT_DIR/wallet_transaction.sh"; }
delegate_stake()  { bash "$SCRIPT_DIR/delegate_to_drep.sh"; }
register_drep()   { bash "$SCRIPT_DIR/drep.sh"; }
lock_assets()     { bash "$SCRIPT_DIR/lock_assets.sh"; }
unlock_assets()   { bash "$SCRIPT_DIR/unlock_assets.sh"; }

# ─── Dialog-based menu ────────────────────────────────────────────────────────
CHOICE_TMP="$(mktemp)"
dialog \
  --clear \
  --backtitle "" \
  --title "crd_cli-util4" \
  --no-shadow \
  --colors \
  --menu "\Z1Select action:\Zn" 12 60 8 \
    1 "Generate Keys" \
    2 "Check UTxO" \
    3 "Send ADA" \
    4 "Delegate Stake" \
    5 "Register/Update DRep" \
    6 "Lock Assets" \
    7 "Unlock Assets" \
    8 "Exit" \
  2> "$CHOICE_TMP"

choice="$(<"$CHOICE_TMP")"
rm -f "$CHOICE_TMP"

case $choice in
  1) generate_keys   ;;
  2) check_utxo      ;;
  3) send_ada        ;;
  4) delegate_stake  ;;
  5) register_drep   ;;
  6) lock_assets     ;;
  7) unlock_assets   ;;
  8) exit 0          ;;
  *) dialog --msgbox "Invalid choice" 6 40 ;;
esac
