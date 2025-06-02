# crd\_cli-util4

> Cardano-CLI utilities by “Group 4” in the Smart Contract curriculum

## Overview

This repository provides lightweight shell scripts to simplify common `cardano-cli` workflows: key generation, address creation, UTXO querying, transaction building/signing, and basic Plutus script handling. These scripts serve as learning templates—validate each command against the latest Cardano CLI version before using on mainnet.

## Table of Contents

* [Features](#features)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Scripts & Usage](#scripts--usage)

  * [Keypair & Address Utilities](#keypair--address-utilities)
  * [UTxO & Chain Queries](#utxo--chain-queries)
  * [Transaction Workflows](#transaction-workflows)
  * [Basic Plutus Helpers](#basic-plutus-helpers)
* [Design Philosophy](#design-philosophy)
* [Contributing](#contributing)
* [License](#license)

## Features

* **Modular Shell Scripts**: Each script focuses on a single task (e.g., generate keypair, build transaction).
* **Minimal Dependencies**: Only `cardano-cli`, optional `jq`, and standard POSIX tools.
* **Network Configuration**: Configurable `NETWORK` and `PROTOCOL_FILE` variables at the top of each script for testnet or mainnet.
* **Sanity Checks**: Scripts verify required files/directories exist and prompt if something is missing.
* **Extensible Templates**: Configuration blocks isolate CLI version variables so you can update flags as Cardano evolves (e.g., reference inputs, inline datums).

## Prerequisites

1. **Cardano Node & CLI**: Install a recent release of [cardano-node](https://github.com/input-output-hk/cardano-node) and ensure `cardano-cli` is in your `PATH`. Verify with:

   ```bash
   cardano-cli --version
   ```
2. **Repository Structure (Recommended)**:

   ```
   crd_cli-util4/
   ├─ keys/            # (Optional) store generated keys
   ├─ scripts/         # All utility scripts
   │   ├─ generate_keys.sh
   │   ├─ query_utxo.sh
   │   ├─ build_tx.sh
   │   ├─ sign_tx.sh
   │   ├─ submit_tx.sh
   │   ├─ create_plutus_script_address.sh
   │   └─ spend_from_script.sh
   ├─ protocol.json    # Protocol parameters JSON
   └─ README.md
   ```
3. **Unix Tools**: `jq` (recommended for JSON parsing) and standard POSIX commands (`grep`, `awk`, `sed`, `mkdir`, etc.).

## Installation

1. **Clone & Enter**

   ```bash
   git clone https://github.com/Minhcardanian/crd_cli-util4.git
   cd crd_cli-util4
   ```
2. **Make Scripts Executable**

   ```bash
   chmod +x scripts/*.sh
   ```
3. **Get Protocol Parameters**

   ```bash
   cardano-cli query protocol-parameters \
     --testnet-magic 1097911063 \
     --out-file protocol.json
   ```

   Save `protocol.json` at the repo root or adjust `PROTOCOL_FILE` in each script.
4. **Configure Variables**
   At the top of each script, edit:

   ```bash
   NETWORK="--testnet-magic 1097911063"
   PROTOCOL_FILE="protocol.json"
   SCRIPTS_DIR="\$(dirname "\$0")"
   KEYS_DIR="../keys"
   ```

## Scripts & Usage

### Keypair & Address Utilities

#### `scripts/generate_keys.sh`

Generates a payment keypair and derives the address.

```bash
Usage:
  ./scripts/generate_keys.sh <wallet-name>

Example:
  ./scripts/generate_keys.sh alice-wallet
  # → Creates:
  #   keys/alice-wallet.payment.vkey
  #   keys/alice-wallet.payment.skey
  #   keys/alice-wallet.payment.addr
```

* Checks for `cardano-cli` in `PATH`.
* Verifies/creates `keys/` directory.
* Runs:

  ```bash
  cardano-cli address key-gen \
    --verification-key-file keys/alice-wallet.payment.vkey \
    --signing-key-file      keys/alice-wallet.payment.skey

  cardano-cli address build \
    ${NETWORK} \
    --payment-verification-key-file keys/alice-wallet.payment.vkey \
    --out-file keys/alice-wallet.payment.addr
  ```

> **Note**: Store keys securely (e.g., hardware wallet, encrypted vault); these scripts write plain-text files.

### UTxO & Chain Queries

#### `scripts/query_utxo.sh`

Lists UTxOs for a given address, optionally pretty-printed with `jq`.

```bash
Usage:
  ./scripts/query_utxo.sh <payment.addr> [--json]

Examples:
  ./scripts/query_utxo.sh keys/alice-wallet.payment.addr
  ./scripts/query_utxo.sh keys/alice-wallet.payment.addr --json
```

* If `jq` is installed and `--json` is passed, outputs formatted JSON; else uses default CLI table.

#### `scripts/query_tip.sh`

Fetches the current chain tip (slot, epoch, block).

```bash
Usage:
  ./scripts/query_tip.sh

Example:
  ./scripts/query_tip.sh
  # → "At epoch 296, block 1234567, slot 4567890"
```

### Transaction Workflows

> **Forward-Looking**: As Cardano adds features (inline datums, reference inputs), update these scripts accordingly.

#### `scripts/build_tx.sh`

Aggregates UTxOs, calculates fees, and constructs a raw transaction (no signing).

```bash
Usage:
  ./scripts/build_tx.sh \
    --sender-addr <sender.addr> \
    --receiver-addr <receiver.addr> \
    --sender-skey  <sender.skey> \
    [--amount <lovelace>] \
    [--metadata-file <file.json>] \
    [--out-tx <raw.tx>]

Example:
  ./scripts/build_tx.sh \
    --sender-addr keys/alice-wallet.payment.addr \
    --receiver-addr keys/bob-wallet.payment.addr \
    --sender-skey keys/alice-wallet.payment.skey \
    --amount 2000000 \
    --out-tx tx.raw
```

1. Queries UTxOs at sender address.
2. Calculates minimum fee via `cardano-cli transaction calculate-min-fee`.
3. Builds raw transaction with placeholder TTL.
4. Outputs `tx.raw` ready for signing.

> **Check**: Does it handle multi-asset? Not yet; extend `--tx-out` or add `--mint` flags as needed.

#### `scripts/sign_tx.sh`

Signs a raw transaction with one or more signing keys.

```bash
Usage:
  ./scripts/sign_tx.sh \
    --tx-body <raw.tx> \
    --signing-keys <skey1> [<skey2> ...] \
    --out-file <signed.tx>

Example:
  ./scripts.sign_tx.sh \
    --tx-body tx.raw \
    --signing-keys keys/alice-wallet.payment.skey \
    --out-file tx.signed
```

* Chain multiple `--signing-key-file` options for multi-signature or script-witness transactions.
* Verify TX body hash matches intended inputs/outputs.

#### `scripts/submit_tx.sh`

Submits a signed transaction to the node.

```bash
Usage:
  ./scripts/submit_tx.sh \
    --signed-tx <signed.tx>

Example:
  ./scripts/submit_tx.sh --signed-tx tx.signed
```

* Confirms success via node response.
* Fails if node is offline or network tag is wrong.

### Basic Plutus Helpers

> **Skepticism**: Always simulate on testnet, verify datum/redeemer schema, and confirm script budget usage.

#### `scripts/create_plutus_script_address.sh`

Derives a script address from a compiled Plutus script and optional datum hash.

```bash
Usage:
  ./scripts/create_plutus_script_address.sh \
    --script-file <script.plutus> \
    [--datum-hash <datum.hash>] \
    --out-file <script.addr>

Example:
  ./scripts/create_plutus_script_address.sh \
    --script-file contracts/myscript.plutus \
    --out-file contracts/myscript.addr
```

* Reads script CBOR, runs `cardano-cli address build-script` with proper flags.

#### `scripts/spend_from_script.sh`

Builds and submits a transaction spending from a script output, providing redeemer and datum.

```bash
Usage:
  ./scripts/spend_from_script.sh \
    --script-address <script.addr> \
    --script-file    <script.plutus> \
    --datum-file     <datum.json> \
    --redeemer-file  <redeemer.json> \
    --output-addr    <receiver.addr> \
    --signing-keys   <skey1> [<skey2> ...] \
    --out-tx         <raw.tx> \
    --network-param  " <--testnet-magic 1097911063>"

Example:
  ./scripts/spend_from_script.sh \
    --script-address contracts/myscript.addr \
    --script-file    contracts/myscript.plutus \
    --datum-file     contracts/datum.json \
    --redeemer-file  contracts/redeemer.json \
    --output-addr    keys/alice-wallet.payment.addr \
    --signing-keys   keys/alice-wallet.payment.skey \
    --out-tx         tx_spend.raw
```

* Validates datum/redeemer schema against compiled script.
* Use `cardano-cli transaction build` with script-related flags; always test on testnet first.

## Design Philosophy

1. **Transparency & Learning**: Plain shell scripts—with comments explaining CLI flags—help you understand UTxO aggregation, fee calculation, and Plutus cost estimation.
2. **Modularity & Extensibility**: Configuration blocks isolate network and file-path variables. When new CLI flags appear (reference inputs, inline datums), update only those blocks.
3. **Security Mindset**: Keys are stored externally; signing is always explicit. For hardware-wallet integration, extend these templates with appropriate flags (e.g., `--witness-slot`, hardware wallet CLI options).

## Contributing

1. **Fork & Branch**: Create a descriptive branch name (e.g., `feature/inline-datums`).
2. **Examples & Tests**: Add an `examples/` entry for each new or modified script.
3. **Update Documentation**: Reflect any changes to CLI flags or usage examples in this README.
4. **Security Audit**: Note any new security considerations (e.g., handling private keys).
5. **Submit a Pull Request**: We review for correctness on testnet/mainnet before merging.

## License

This project is released under the **MIT License**. See [LICENSE](LICENSE) for details.
