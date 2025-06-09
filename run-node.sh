#!/bin/bash
source "$(dirname "$0")/config.sh"

# Set environment variable
export CARDANO_NODE_SOCKET_PATH="$SOCKET_PATH"

# Function to check if the node is running
is_node_running() {
  pgrep -f "cardano-node.*--database-path $DB_PATH" > /dev/null
  echo $?
}

# Function to check synchronization status
check_sync_status() {
  $CARDANO_CLI query tip $NETWORK 2>/dev/null | grep "syncProgress" | awk -F'"' '{print $4}'
}

# Function to start the node
start_node() {
  nohup "$CARDANO_NODE_PATH/bin/cardano-node" run \
    --topology "$TOPOLOGY" \
    --database-path "$DB_PATH" \
    --socket-path "$SOCKET_PATH" \
    --host-addr "$HOST_ADDR" \
    --port "$PORT" \
    --config "$CONFIG" > /dev/null 2>&1 &
}

# Function to stop the node
stop_node() {
  pkill -f "cardano-node.*--database-path $DB_PATH"
  echo "Node has been stopped."
}

# Check if the node is running
if [[ $(is_node_running) -ne 0 ]]; then
  echo "The node is not running. Do you want to start the node? (y/n)"
  read -r choice
  if [[ "$choice" == "y" ]]; then
    start_node
  else
    echo "Exiting without starting the node."
    exit 0
  fi
else
  echo "The node is already running."
fi

# Initialize previous sync status to track changes
previous_sync_status=""

# Loop to check synchronization status only if the node is running
while [[ $(is_node_running) -eq 0 ]]; do
  sync_status=$(check_sync_status)
  if [[ -z "$sync_status" ]]; then
    echo "The node is starting...."
    echo "Press 's' to stop the node or 'ESC' to return to main menu."
  else
    if [[ "$sync_status" != "$previous_sync_status" ]]; then
      echo "Synchronization status: $sync_status%"
      echo "Press 's' to stop the node or 'ESC' to return to main menu."
      previous_sync_status="$sync_status"
      if [[ "$sync_status" == "100.00" ]]; then
        echo "The node is fully synchronized."
      fi
    fi
  fi

  # Read user input
  read -n 1 -t 2 user_input
  case "$user_input" in
    s)
      stop_node
      exit 0
      ;;
    $'\e')
      echo "Returning to main menu..."
      exit 0
      ;;
  esac
done

echo "The node is no longer running. Exiting!"
