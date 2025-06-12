#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

# ─── Prereqs ────────────────────────────────────────────────────────────────────
command -v "$CARDANO_ADDRESS" > /dev/null 2>&1 \
  || { echo "Error: CARDANO_ADDRESS ('$CARDANO_ADDRESS') not found"; exit 1; }
command -v "$CARDANO_CLI"     > /dev/null 2>&1 \
  || { echo "Error: CARDANO_CLI ('$CARDANO_CLI') not found"; exit 1; }

# ─── Generate recovery phrase ───────────────────────────────────────────────────
echo "Generating 24-word recovery phrase..."
$CARDANO_ADDRESS recovery-phrase generate --size 24 > phrase.prv
check_command $? "Failed to generate recovery phrase"
echo "→ Saved to phrase.prv"

# ─── Derive root key ─────────────────────────────────────────────────────────────
echo "Deriving root key from recovery phrase..."
$CARDANO_ADDRESS key from-recovery-phrase Shelley < phrase.prv > root.prv
check_command $? "Failed to derive root key"

# ─── Derive payment key pair ────────────────────────────────────────────────────
echo "Deriving payment key pair..."
$CARDANO_ADDRESS key child 1852H/1815H/0H/0/0 < root.prv > payment.prv
check_command $? "Failed to derive payment.prv"
$CARDANO_ADDRESS key public --without-chain-code < payment.prv > payment.pub
check_command $? "Failed to derive payment.pub"

echo "Converting payment key for cardano-cli..."
$CARDANO_CLI key convert-cardano-address-key \
    --shelley-payment-key \
    --signing-key-file payment.prv \
    --out-file payment.skey
check_command $? "Failed to convert payment.skey"

$CARDANO_CLI key verification-key \
    --signing-key-file payment.skey \
    --verification-key-file payment.vkey
check_command $? "Failed to make payment.vkey"

# ─── Derive stake key pair ──────────────────────────────────────────────────────
echo "Deriving stake key pair..."
cat root.prv | $CARDANO_ADDRESS key child 1852H/1815H/0H/2/0 > stake.prv
check_command $? "Failed to derive stake.prv"

$CARDANO_CLI key convert-cardano-address-key \
    --signing-key-file stake.prv \
    --shelley-stake-key \
    --out-file stake.skey
check_command $? "Failed to convert stake.skey"

$CARDANO_CLI key verification-key \
    --signing-key-file stake.skey \
    --verification-key-file stake.vkey
check_command $? "Failed to make stake.vkey"

# clean up intermediate files
rm -f root.prv stake.prv

# ─── Build addresses ────────────────────────────────────────────────────────────
echo "Building payment address..."
$CARDANO_CLI address build \
    --payment-verification-key-file payment.vkey \
    $NETWORK \
    --stake-verification-key-file stake.vkey \
    --out-file payment.addr
check_command $? "Failed to build payment.addr"

echo "Building stake address..."
$CARDANO_CLI stake-address build \
    --stake-verification-key-file stake.vkey \
    --out-file stake.addr \
    $NETWORK
check_command $? "Failed to build stake.addr"

# ─── Done ───────────────────────────────────────────────────────────────────────
echo
echo "✅ Wallet generation complete!"
echo " - Recovery phrase: phrase.prv"
echo " - Payment address: $(<payment.addr)"
echo " - Stake address:   $(<stake.addr)"
echo
echo "Stored files:"
echo " • payment.prv"
echo " • payment.pub"
echo " • payment.skey"
echo " • payment.vkey"
echo " • stake.skey"
echo " • stake.vkey"
echo " • payment.addr"
echo " • stake.addr"
