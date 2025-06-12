#!/usr/bin/env bash
set -euo pipefail

# ─── Base directory of the repo ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── cardano-cli / address ─────────────────────────────────────────────────────
export CARDANO_CLI="${CARDANO_CLI:-cardano-cli}"
export CARDANO_ADDRESS="${CARDANO_ADDRESS:-cardano-address}"

# ─── Network & protocol params ─────────────────────────────────────────────────
export NETWORK="${NETWORK:---testnet-magic 2}"
export PROTOCOL_PARAMS="${PROTOCOL_PARAMS:-$SCRIPT_DIR/protocol.json}"

# ─── Auto-detect the node socket ────────────────────────────────────────────────
if [[ -z "${CARDANO_NODE_SOCKET_PATH:-}" ]]; then
  # adjust if your node lives elsewhere
  DEFAULT_SOCKET="$(find "$HOME/cardano" -type s -name "*.socket" 2>/dev/null | head -n1)"
  if [[ -n "$DEFAULT_SOCKET" ]]; then
    export CARDANO_NODE_SOCKET_PATH="$DEFAULT_SOCKET"
  else
    export CARDANO_NODE_SOCKET_PATH="$SCRIPT_DIR/db/node.socket"
  fi
fi

# ─── Default wallet files ───────────────────────────────────────────────────────
export PAYMENT_ADDR_FILE="${PAYMENT_ADDR_FILE:-$SCRIPT_DIR/payment.addr}"
export SIGNING_KEY_FILE="${SIGNING_KEY_FILE:-$SCRIPT_DIR/payment.skey}"

# ─── Optional: node-run defaults (only if you use run-node.sh) ─────────────────
: "${DB_PATH:=$SCRIPT_DIR/db}"
: "${CARDANO_NODE_PATH:=$SCRIPT_DIR/cardano-node}"
: "${TOPOLOGY:=$SCRIPT_DIR/configuration/testnet-topology.json}"
: "${CONFIG:=$SCRIPT_DIR/configuration/testnet-config.json}"
: "${HOST_ADDR:=0.0.0.0}"
: "${PORT:=3001}"

# ─── Debug info (only if DEBUG=true) ────────────────────────────────────────────
if [[ "${DEBUG:-false}" == "true" ]]; then
  echo "CARDANO_CLI         = $CARDANO_CLI"
  echo "CARDANO_ADDRESS     = $CARDANO_ADDRESS"
  echo "CARDANO_NODE_SOCKET = $CARDANO_NODE_SOCKET_PATH"
  echo "NETWORK             = $NETWORK"
  echo "PROTOCOL_PARAMS     = $PROTOCOL_PARAMS"
  echo "PAYMENT_ADDR_FILE   = $PAYMENT_ADDR_FILE"
  echo "SIGNING_KEY_FILE    = $SIGNING_KEY_FILE"
fi
