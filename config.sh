#!/bin/bash

# Base directory of the repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to cardano-cli executable
CARDANO_CLI=${CARDANO_CLI:-cardano-cli}

# Path to cardano-address executable
CARDANO_ADDRESS=${CARDANO_ADDRESS:-cardano-address}

# Path to the node socket
export CARDANO_NODE_SOCKET_PATH=${CARDANO_NODE_SOCKET_PATH:-"$SCRIPT_DIR/db/node.socket"}

# Network flag to use with cardano-cli commands
NETWORK=${NETWORK:---testnet-magic 2}

# Protocol parameters file
PROTOCOL_PARAMS=${PROTOCOL_PARAMS:-"protocol.json"}

# cardano-node settings (used by run-node.sh)
CARDANO_NODE_PATH=${CARDANO_NODE_PATH:-"$SCRIPT_DIR/cardano-node"}
TOPOLOGY=${TOPOLOGY:-"$CARDANO_NODE_PATH/share/preview/topology.json"}
DB_PATH=${DB_PATH:-"$CARDANO_NODE_PATH/db"}
SOCKET_PATH=${SOCKET_PATH:-"$CARDANO_NODE_PATH/db/node.socket"}
HOST_ADDR=${HOST_ADDR:-"0.0.0.0"}
PORT=${PORT:-"3001"}
CONFIG=${CONFIG:-"$CARDANO_NODE_PATH/share/preview/config.json"}

# Directory for generated keys
KEYS_DIR=${KEYS_DIR:-"$SCRIPT_DIR/keys"}
