#!/usr/bin/env bash
set -euo pipefail

# ─── Setup & Shared Libraries ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in config.sh lib.sh file_utils.sh select-utxo.sh; do
  [[ -f "$SCRIPT_DIR/$f" ]] || { echo "Missing $f in $SCRIPT_DIR" >&2; exit 1; }
  source "$SCRIPT_DIR/$f"
done

# ─── Helpers ───────────────────────────────────────────────────────────────────
check_command() {
  if [[ $1 -ne 0 ]]; then
    echo "Error: $2" >&2
    exit 1
  fi
}

# ─── 1) Register as a DRep ──────────────────────────────────────────────────────
register() {
  echo "🗝️  Generating DRep key pair…"
  $CARDANO_CLI conway governance drep key-gen \
    --verification-key-file drep.vkey \
    --signing-key-file drep.skey
  check_command $? "dRep key generation failed"

  echo "🌐  Downloading DRep metadata…"
  wget -q -O drep.jsonld \
    https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0119/examples/drep.jsonld
  check_command $? "Failed to download metadata"

  echo "🔍  Calculating metadata hash…"
  metadata_hash=$(
    $CARDANO_CLI conway governance drep metadata-hash \
      --drep-metadata-file drep.jsonld
  )
  check_command $? "Failed to compute metadata hash"

  echo "📜  Building registration certificate…"
  $CARDANO_CLI conway governance drep registration-certificate \
    --drep-verification-key-file drep.vkey \
    --key-reg-deposit-amt 500000000 \
    --drep-metadata-url https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0119/examples/drep.jsonld \
    --drep-metadata-hash "$metadata_hash" \
    --out-file drep-reg.cert
  check_command $? "Failed to build registration cert"

  echo "💸  Selecting UTxO for fees…"
  select_utxo payment
  tx_in="$SELECTED_UTXO"

  echo "🏗️  Building registration transaction…"
  build_tx \
    --tx-in "$tx_in" \
    --change-address "$(< payment.addr)" \
    --certificate-file drep-reg.cert \
    --witness-override 2 \
    --out-file drep.tx
  check_command $? "Failed to build registration tx"

  echo "✍️  Signing registration transaction…"
  sign_tx \
    --tx-body-file drep.tx \
    --signing-key-file payment.skey \
    --signing-key-file drep.skey \
    --out-file drep.signed
  check_command $? "Failed to sign registration tx"

  echo "🚀  Submitting registration transaction…"
  submit_tx --tx-file drep.signed
  check_command $? "Failed to submit registration tx"

  txid=$($CARDANO_CLI conway transaction txid --tx-file drep.signed)
  echo "✅ DRep registered! TXID: $txid"

  echo "🆔  Exporting DRep ID…"
  $CARDANO_CLI conway governance drep id $NETWORK \
    --drep-verification-key-file drep.vkey \
    --output-format hex > drep.id
  echo "→ dRep ID written to drep.id"
}

# ─── 2) Create & Submit a Vote ─────────────────────────────────────────────────
vote() {
  echo "📖  Fetching governance state…"
  $CARDANO_CLI conway query gov-state $NETWORK > gov-state.json
  check_command $? "Failed to query governance state"

  echo "✏️  Creating vote file…"
  read -rp "Governance action tx-id: " ga_tx
  read -rp "Governance action index: " ga_idx
  vote_file="${ga_tx}-${ga_idx}.vote"

  $CARDANO_CLI conway governance vote create \
    --yes \
    --governance-action-tx-id "$ga_tx" \
    --governance-action-index "$ga_idx" \
    --drep-verification-key-file drep.vkey \
    --out-file "$vote_file"
  check_command $? "Failed to create vote file"

  echo "💸  Selecting UTxO for vote fees…"
  select_utxo payment
  tx_in="$SELECTED_UTXO"

  echo "🏗️  Building vote transaction…"
  build_tx \
    --tx-in "$tx_in" \
    --change-address "$(< payment.addr)" \
    --vote-file "$vote_file" \
    --witness-override 2 \
    --out-file vote.tx
  check_command $? "Failed to build vote tx"

  echo "✍️  Signing vote transaction…"
  sign_tx \
    --tx-body-file vote.tx \
    --signing-key-file drep.skey \
    --signing-key-file payment.skey \
    --out-file vote.signed
  check_command $? "Failed to sign vote tx"

  echo "🚀  Submitting vote transaction…"
  submit_tx --tx-file vote.signed
  check_command $? "Failed to submit vote tx"

  txid=$($CARDANO_CLI conway transaction txid --tx-file vote.signed)
  echo "✅ Vote submitted! TXID: $txid"
}

# ─── 3) Delegate Vote to Another DRep ──────────────────────────────────────────
delegate() {
  echo "🔄  Delegating vote to another DRep…"
  bash "$SCRIPT_DIR/delegate_to_drep.sh"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────
if (( $# != 1 )); then
  echo "Usage: $(basename "$0") <register|vote|delegate>" >&2
  exit 1
fi

case "$1" in
  register) register   ;;
  vote)     vote       ;;
  delegate) delegate   ;;
  *) echo "Invalid command: $1" >&2; exit 1 ;;
esac
