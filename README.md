# crd\_cli-util4

> Cardano-CLI utilities by “Group 4” in the Smart Contract curriculum

## Overview

Lightweight shell scripts to simplify common `cardano-cli` workflows: key generation, address creation, UTxO querying, transaction building/signing, and basic Plutus script handling. Validate every command against the latest CLI before mainnet use.

## Table of Contents

* [Features](#features)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Scripts & Usage](#scripts--usage)
* [Terminal UI Implementation](#terminal-ui-implementation)
* [Design Philosophy](#design-philosophy)
* [Tasks to Complete for Production](#tasks-to-complete-for-production)
* [Contributing](#contributing)
* [License](#license)

## Features

* **Modular Shell Scripts:** Single-purpose scripts (generate keys, build TX, sign TX, etc.) under `scripts/`.
* **Minimal Dependencies:** Only `cardano-cli`, optional `jq`, POSIX tools, and (for UI) `whiptail`.
* **Configurable Network:** Change `NETWORK` and `PROTOCOL_FILE` in one place.
* **Sanity Checks:** Verify required files/directories; prompt on missing inputs.
* **Extensible Templates:** Easily update flags for new era features (inline datums, reference inputs).

## Prerequisites

1. **Cardano Node & CLI:** Install [cardano-node](https://github.com/input-output-hk/cardano-node) and ensure `cardano-cli --version` works.
2. **Directory Layout (Recommended):**

   ```text
   crd_cli-util4/
   ├─ config.sh             # network and path settings
   ├─ lib.sh                # core functions extracted from scripts
   ├─ menu.sh               # interactive UI wrapper
   ├─ scripts/              # original CLI scripts
   ├─ examples/             # demo flows, including UI examples
   ├─ protocol.json         # protocol parameters
   └─ keys/                 # generated keys and addresses
   ```
3. **Unix Tools:** `jq` for JSON parsing; `whiptail` (normally preinstalled on Debian/Ubuntu) for the UI.

## Installation

```bash
git clone https://github.com/Minhcardanian/crd_cli-util4.git
cd crd_cli-util4
chmod +x scripts/*.sh lib.sh menu.sh
cardano-cli query protocol-parameters --testnet-magic 1097911063 --out-file protocol.json
```

Edit `config.sh` as needed:

```bash
NETWORK="--testnet-magic 1097911063"
PROTOCOL_FILE="protocol.json"
KEYS_DIR="./keys"
```

## Scripts & Usage

| Script                                    | Description                                                                                                                                                                        |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/generate_keys.sh <wallet-name>`  | Generate payment keypair and address.                                                                                                                                              |
| `scripts/query_utxo.sh <.addr> [--json]`  | List UTxOs for an address (JSON output optional).                                                                                                                                  |
| `scripts/query_tip.sh`                    | Show current epoch, slot, and block height.                                                                                                                                        |
| `scripts/build_tx.sh`                     | Build a raw transaction (`--sender-addr`, `--receiver-addr`, `--sender-skey`, optional `--amount`, `--metadata-file`, `--out-tx`).                                                 |
| `scripts/sign_tx.sh`                      | Sign a raw transaction (`--tx-body`, `--signing-keys`, `--out-file`).                                                                                                              |
| `scripts/submit_tx.sh`                    | Submit a signed transaction to the node (`--signed-tx`).                                                                                                                           |
| `scripts/create_plutus_script_address.sh` | Derive a Plutus script address from a compiled `.plutus` file and optional datum hash.                                                                                             |
| `scripts/spend_from_script.sh`            | Build and submit a transaction spending from a script output (requires `--script-address`, `--script-file`, `--datum-file`, `--redeemer-file`, `--output-addr`, `--signing-keys`). |

## Terminal UI Implementation

To guide users through offline/online steps with a menu-driven interface, we provide a **whiptail** wrapper.

### Project Structure for UI

```text
crd_cli-util4/
├─ config.sh
├─ lib.sh
├─ menu.sh
├─ scripts/
├─ examples/
└─ keys/
```

### config.sh

```bash
#!/usr/bin/env bash
NETWORK="--testnet-magic 1097911063"
PROTOCOL_FILE="protocol.json"
KEYS_DIR="./keys"
```

### lib.sh (extract functions)

```bash
#!/usr/bin/env bash
set -euo pipefail

generate_keys() {
  local name="$1"
  mkdir -p "$KEYS_DIR"
  cardano-cli address key-gen --verification-key-file "$KEYS_DIR/${name}.payment.vkey" --signing-key-file "$KEYS_DIR/${name}.payment.skey"
  cardano-cli address build ${NETWORK} --payment-verification-key-file "$KEYS_DIR/${name}.payment.vkey" --out-file "$KEYS_DIR/${name}.payment.addr"
  echo "Keys and address generated in $KEYS_DIR"
}
# Similarly extract build_tx(), sign_tx(), submit_tx(), create_script_address(), spend_from_script()
```

### menu.sh (whiptail example)

```bash
#!/usr/bin/env bash
set -euo pipefail
source ./config.sh
source ./lib.sh

while true; do
  CHOICE=$(whiptail --backtitle "crd_cli-util4 GUI" --title "Main Menu" --menu "Select action:" 15 60 6 \
    1 "Generate Keys" 2 "Build Transaction" 3 "Sign Transaction" 4 "Submit Transaction" 5 "Plutus Utilities" 6 "Exit" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && break
  clear
  case "$CHOICE" in
    1) name=$(whiptail --inputbox "Wallet name:" 8 40 3>&1 1>&2 2>&3); generate_keys "$name";;
    2) build_tx_flow;;
    3) sign_tx_flow;;
    4) submit_tx_flow;;
    5) plutus_menu;;
    6) break;;
  esac
  read -p "Press ENTER to continue..."
done
clear
```

* **Flow functions** (`build_tx_flow`, etc.) prompt via `whiptail` then call corresponding `lib.sh` functions.
* Place full UI demos in `examples/` so users can see complete scripts without altering core logic.

## Design Philosophy

1. **Transparency & Learning:** Plain shell + whiptail menus expose every step of the CLI workflow.
2. **Modularity:** Single `config.sh` + `lib.sh` for reusable code; `menu.sh` for UI.
3. **Offline/Online Separation:** UI can warn or disable options based on node connectivity.

## Tasks to Complete for Production

| Task                                              | Subtasks                                                                                                                                                                                                                    | Status |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| **Centralize Configuration**                      | - Extract network, file-path, and protocol settings into `config.sh`  <br> - Update all scripts and the UI to source `config.sh`                                                                                            |  Done  |
| **Refactor Core Logic into `lib.sh`**             | - Encapsulate UTxO selection, fee calculation, transaction building, signing, submission, and Plutus helpers  <br> - Have both CLI scripts and the UI source these functions for consistency                                |  Done  |
| **Implement Terminal UI Skeleton**                | - Define architecture of `menu.sh`, `config.sh`, and `lib.sh`  <br> - Map the user flow for each operation  <br> - Identify optimizations: input validation, progress bars, caching                                         |  \[ ]  |
| **Populate `examples/` Directory**                | - Provide end-to-end example scripts for common flows (send ADA, mint token, spend script)  <br> - Document preconditions, outputs, and verification steps                                                                  |  \[ ]  |
| **Add Multi-Asset & Advanced Plutus Support**     | - Extend fee-calculation and UTxO parsing for native tokens  <br> - Introduce flags and helpers for inline datums and reference inputs  <br> - Update the UI to let users select token bundles and script options           |  \[ ]  |
| **Integrate Hardware-Wallet & Key-Vault Options** | - Add a hardware-wallet signing flow with `cardano-hw-cli`  <br> - Offer encrypted-vault signing using GPG for private keys                                                                                                 |  \[ ]  |
| **Automated Testing & CI Pipeline**               | - Write shell/unit tests for each `lib.sh` function  <br> - Implement a GitHub Actions workflow that spins up a sandbox node and runs example flows to verify on-chain effects                                              |  \[ ]  |
| **Robust Error Handling & UX Polish**             | - Ensure input prompts validate and loop until correct  <br> - Provide clear error messages and confirmations before irreversible actions                                                                                   |  \[ ]  |
| **Comprehensive Documentation**                   | - Update README with tasks, terminal UI overview, and scripts table  <br> - Maintain a versioned CHANGELOG                                                                                                                  |  \[ ]  |
| **Release & Versioning Strategy**                 | - Tag a `v1.0` release when core flows are stable and tested  <br> - Define branching (e.g., `main` for prod, `dev` for features)  <br> - Publish release assets including `config.sh`, `lib.sh`, `menu.sh`, and `scripts/` |  \[ ]  |

## Contributing

1. Fork & branch (e.g., `feature/ui-dialog`).
2. Add or update UI examples in `examples/`.
3. Ensure new flows source `config.sh` + `lib.sh` and update README accordingly.
4. Submit a PR with tests or manual instructions for verifying the UI.

## License

This project is released under the **MIT License**. See [LICENSE](LICENSE) for details.
