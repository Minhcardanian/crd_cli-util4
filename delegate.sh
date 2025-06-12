#!/usr/bin/env bash
set -euo pipefail

# ─── Setup & Config Loading ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LIB_FILE="$SCRIPT_DIR/lib.sh"
WRAPPER="${PREVIEW_NODE_SCRIPT:-"$HOME/preview-node.sh"}"
LOG_FILE="$SCRIPT_DIR/node.log"

# sanity checks
[[ -f "$CONFIG_FILE" && -f "$LIB_FILE" ]] || {
  echo "Error: config.sh or lib.sh missing in $SCRIPT_DIR" >&2
  exit 1
}
[[ -x "$WRAPPER" ]] || {
  echo "Error: preview-node.sh not found or not executable at $WRAPPER" >&2
  exit 1
}

source "$CONFIG_FILE"
source "$LIB_FILE"
: "${CONFIG:=$SCRIPT_DIR/configuration/testnet-config.json}"

# ─── Helpers ───────────────────────────────────────────────────────────────────
is_wrapper_running() {
  pgrep -f "$WRAPPER.*run" >/dev/null
}

get_tip() {
  local json block pct
  json="$(
    $CARDANO_CLI query tip \
      --socket-path "$CARDANO_NODE_SOCKET_PATH" \
      $NETWORK 2>/dev/null
  )" || return 1
  block=$(grep -oP '"block":\s*\K[0-9]+' <<<"$json")
  pct=$(grep -oP '"syncProgress":\s*"\K[0-9.]+' <<<"$json")
  printf "%s|%s\n" "${block:-?}" "${pct:-0}"
}

# ─── Kill everything: wrapper, child node, socket, and log ──────────────────────
kill_node_processes() {
  # kill the preview-node.sh wrapper
  [[ -n "${PREVIEW_PID-}" ]] && kill "$PREVIEW_PID" 2>/dev/null || :
  # kill any cardano-node processes started by it
  pkill -f "cardano-node run" 2>/dev/null || :
  # remove the socket and log
  rm -f "$CARDANO_NODE_SOCKET_PATH" "$LOG_FILE"
}

# ─── Trap Ctrl+C / SIGTERM to clean up ─────────────────────────────────────────
trap 'echo; echo "Interrupted — stopping node…"; kill_node_processes; exit 1' INT TERM

# ─── Start/stop wrappers ────────────────────────────────────────────────────────
start_node() {
  echo "Starting preview-node.sh (logging to $LOG_FILE)…"
  bash "$WRAPPER" run > "$LOG_FILE" 2>&1 &
  PREVIEW_PID=$!
  sleep 1
  echo "Launched PID $PREVIEW_PID."
}

stop_node() {
  echo -e "\nStopping node (PID $PREVIEW_PID)…"
  kill_node_processes
  wait "$PREVIEW_PID" 2>/dev/null || :
  echo "Node and wrapper stopped."
}

# ─── Purge any stale instance ──────────────────────────────────────────────────
if is_wrapper_running; then
  PREVIEW_PID=$(pgrep -f "$WRAPPER.*run")
  echo "Found existing preview-node.sh (PID $PREVIEW_PID)."
  read -rp "Kill it and start fresh? (y/n) " killit
  if [[ "$killit" =~ ^[Yy]$ ]]; then
    stop_node
    unset PREVIEW_PID
  else
    echo "Reusing existing node (PID $PREVIEW_PID)."
  fi
fi

# ─── Interactive start flow ───────────────────────────────────────────────────
if ! is_wrapper_running; then
  read -rp "Node is not running. Start it now? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    start_node
  else
    echo "Aborted."
    exit 0
  fi
else
  PREVIEW_PID=${PREVIEW_PID:-$(pgrep -f "$WRAPPER.*run")}
fi

# ─── Wait for socket to appear ─────────────────────────────────────────────────
while ! is_wrapper_running; do
  printf "Waiting for preview-node.sh…  \r"
  sleep 1
done

echo "Node detected. Press 's' to stop or ESC to exit."

# ─── Monitor loop with live Block & Sync display ─────────────────────────────
while is_wrapper_running; do
  # defaults if tip fails
  blk="---"; pct="0.00"
  if tip_info=$(get_tip); then
    IFS='|' read -r blk pct <<<"$tip_info"
  fi
  printf "\rBlock: %6s | Sync: %6s%%" "$blk" "$pct"

  # once fully synced, announce and break
  if (( ${pct%%.*} >= 100 )); then
    echo -e "\n\033[1;32mNode fully synchronized at block $blk.\033[0m"
    break
  fi

  # check for s or ESC
  if IFS= read -rsn1 -t 1 key; then
    case "$key" in
      s) stop_node; exit 0 ;;
      $'\e') echo -e "\nReturning to menu…"; exit 0 ;;
    esac
  fi
done

# ─── Post-sync prompt ──────────────────────────────────────────────────────────
while true; do
  read -rp "Press 's' to stop node or ESC to return: " -n1 key
  case "$key" in
    s) stop_node; exit 0 ;;
    $'\e') echo ""; echo "Returning to menu…"; exit 0 ;;
  esac
done
