#!/usr/bin/env bash
set -euo pipefail

# Create a new wallet (generate keys, encrypt seed, write to ~/.crd_cli-gui)
create_wallet() {
  mkdir -p "$HOME/.crd_cli-gui"
  # ... generate keys, write encrypted seed to $HOME/.crd_cli-gui/seed.enc
  echo "create_wallet not implemented" >&2
}

# Show the wallet address
show_address() {
  # ... read payment.addr or similar
  echo "show_address not implemented" >&2
}

# Verify passphrase
verify_passphrase() {
  local pass="$1"
  # return 0 if pass correct, 1 otherwise
  return 1
}

# Decrypt and return the seed phrase
get_seed_phrase() {
  # ... decrypt $HOME/.crd_cli-gui/seed.enc in-memory
  echo "your seed phrase here"
}
