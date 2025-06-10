#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CARDANO_CLI="${CARDANO_CLI:-cardano-cli}"
export NETWORK="${NETWORK:---testnet-magic 2}"
export PROTOCOL_PARAMS="${PROTOCOL_PARAMS:-$SCRIPT_DIR/protocol.json}"

if [[ -z "${CARDANO_NODE_SOCKET_PATH:-}" ]]; then
  DEFAULT_SOCKET="$(find "$HOME/cardano" -type s -name "*.socket" 2>/dev/null | head -n1)"
  export CARDANO_NODE_SOCKET_PATH="${DEFAULT_SOCKET:-$SCRIPT_DIR/db/node.socket}"
fi

# Optional defaults for run-node.sh
: "${DB_PATH:=$SCRIPT_DIR/db}"
: "${TOPOLOGY:=$SCRIPT_DIR/configuration/testnet-topology.json}"
: "${CONFIG:=$SCRIPT_DIR/configuration/testnet-config.json}"
: "${HOST_ADDR:=0.0.0.0}"
: "${PORT:=3001}"
