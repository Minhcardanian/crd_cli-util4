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
# If the user has already overridden CARDANO_NODE_SOCKET_PATH, keep it.
# Otherwise, search common preview node directories for the first "*.socket" you find.
if [[ -z "${CARDANO_NODE_SOCKET_PATH:-}" ]]; then
  # adjust /home/minhgiga/cardano if your preview-node.sh uses a different base
  DEFAULT_SOCKET="$(find "$HOME/cardano" -type s -name "*.socket" 2>/dev/null | head -n1)"
  if [[ -n "$DEFAULT_SOCKET" ]]; then
    export CARDANO_NODE_SOCKET_PATH="$DEFAULT_SOCKET"
  else
    # fallback to a local db folder
    export CARDANO_NODE_SOCKET_PATH="$SCRIPT_DIR/db/node.socket"
  fi
fi

# ─── Optional: node-run defaults (only if you use run-node.sh) ──────────────────
: "${DB_PATH:=$SCRIPT_DIR/db}"
: "${CARDANO_NODE_PATH:=$SCRIPT_DIR/cardano-node}"
: "${TOPOLOGY:=$SCRIPT_DIR/configuration/testnet-topology.json}"
: "${CONFIG:=$SCRIPT_DIR/configuration/testnet-config.json}"
: "${HOST_ADDR:=0.0.0.0}"
: "${PORT:=3001}"

# ─── Debug info (optional) ─────────────────────────────────────────────────────
echo "Using CARDANO_CLI=$CARDANO_CLI"
echo "Using SOCKET_PATH=$CARDANO_NODE_SOCKET_PATH"
echo "Using NETWORK=$NETWORK"
