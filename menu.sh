#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"
FILE_UTILS="$SCRIPT_DIR/file_utils.sh"

# ensure required files exist
for f in "$CONFIG_FILE" "$LIB_FILE" "$FILE_UTILS"; do
  [[ -f "$f" ]] || { echo "Required $f not found" >&2; exit 1; }
  source "$f"
done

PAYMENT_ADDR_FILE="payment.addr"
SIGNING_KEY_FILE="payment.skey"

# abort-on-failure helper
check_command() {
    if [[ $1 -ne 0 ]]; then
        echo "Error: $2" >&2
        exit 1
    fi
}

# wrappers
generate_keys()       { bash "$SCRIPT_DIR/wallet-generate.sh"; }
start_node()          { bash "$SCRIPT_DIR/run-node.sh";      }
query_utxo()          { bash "$SCRIPT_DIR/check.sh" utxo;     }
check_tx()            { bash "$SCRIPT_DIR/check.sh" txhash;   }
perform_transaction() { bash "$SCRIPT_DIR/wallet-transaction.sh"; }
delegate_stake()      { bash "$SCRIPT_DIR/delegate.sh";       }
lock_asset()          { bash "$SCRIPT_DIR/lock_assets.sh";     }
unlock_asset()        { bash "$SCRIPT_DIR/unlock-asset.sh";    }
governance()          { bash "$SCRIPT_DIR/drep.sh" register;  }

# ─── Pre-flight ───────────────────────────────────────────────────────────────
if [[ ! -f "$PAYMENT_ADDR_FILE" || ! -f "$SIGNING_KEY_FILE" ]]; then
  dialog --msgbox "⚠️  No wallet found.\nPlease select 'Generate keys & address'." 7 50
  clear; generate_keys
fi

UTXO_JSON=$($CARDANO_CLI conway query utxo \
  --address "$( < "$PAYMENT_ADDR_FILE" )" $NETWORK \
  --out-file /dev/stdout 2>/dev/null)

if ! echo "$UTXO_JSON" | jq -e 'length > 0' >/dev/null 2>&1; then
  dialog --msgbox "⚠️  No UTxO at payment address.\nPlease fund it or run 'Query UTxO'." 7 50
fi
# ─────────────────────────────────────────────────────────────────────────────

main_menu() {
  local CHOICE_FILE
  CHOICE_FILE=$(mktemp)
  trap 'rm -f "$CHOICE_FILE"' EXIT

  while true; do
    dialog \
      --clear \
      --backtitle "Cardano CLI Utility" \
      --title "Main Menu" \
      --menu "Select an action:" 15 50 10 \
      1 "Generate keys & address"               \
      2 "Start/Stop node"                       \
      3 "Query UTxO"                            \
      4 "Check TX Hash"                         \
      5 "Perform a simple transaction"          \
      6 "Delegate stake"                        \
      7 "Lock asset to smart contract"          \
      8 "Unlock asset from smart contract"      \
      9 "Governance (dRep + vote)"              \
      10 "Exit"                                 \
      2>"$CHOICE_FILE"

    local ret=$?
    local choice
    choice=$(<"$CHOICE_FILE")

    # Cancel/Esc → exit clean
    [[ $ret -ne 0 ]] && { clear; exit 0; }

    clear
    case "$choice" in
      1) generate_keys            ;;
      2) start_node               ;;
      3) query_utxo               ;;
      4) check_tx                 ;;
      5) perform_transaction      ;;
      6) delegate_stake           ;;
      7) lock_asset               ;;
      8) unlock_asset             ;;
      9) governance               ;;
      10) exit 0                  ;;
      *) dialog --msgbox "Invalid choice." 5 30 ;;
    esac

    read -rp "Press Enter to return to menu…" _
  done
}

main_menu
