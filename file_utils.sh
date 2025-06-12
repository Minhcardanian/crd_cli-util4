#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Ensure key env vars are set (from config.sh)
: "${CARDANO_CLI:?CARDANO_CLI must be set in config.sh}"
: "${NETWORK:?NETWORK must be set in config.sh}"

# Determine script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared config & libs
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib.sh"

# -----------------------------------------------------------------------------
# Prompt user to pick a stake-pool ID by number
# Usage: select_poolid
select_poolid() {
    local pools
    if ! pools=$($CARDANO_CLI query stake-pools $NETWORK 2>/dev/null); then
        echo "Unable to fetch pool list. Check CARDANO_CLI or network." >&2
        return 1
    fi
    if [[ -z "$pools" ]]; then
        echo "No stake pools returned." >&2
        return 1
    fi

    # Break into an array and list with numbers
    mapfile -t pool_list < <(printf '%s\n' $pools)
    echo "Available stake pools:"
    for i in "${!pool_list[@]}"; do
        printf "  %2d) %s\n" "$((i+1))" "${pool_list[$i]}"
    done

    # Loop until valid choice
    local choice
    while true; do
        read -rp "Select pool number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#pool_list[@]} )); then
            POOL_ID="${pool_list[choice-1]}"
            echo "Selected Pool ID: $POOL_ID"
            break
        fi
        echo "Invalid selection. Try again."
    done
}

# -----------------------------------------------------------------------------
# Prompt user to pick a file by number from a subdirectory
# Usage: select_file <subdirectory> <extension>
select_file() {
    local subdirectory=${1:?Usage: select_file <subdirectory> <extension>}
    local file_extension=${2:?Usage: select_file <subdirectory> <extension>}

    local dir="$SCRIPT_DIR/$subdirectory"
    if [[ ! -d "$dir" ]]; then
        echo "Directory not found: $dir" >&2
        return 1
    fi

    # Collect matching files
    shopt -s nullglob
    local files=( "$dir"/*."$file_extension" )
    shopt -u nullglob

    if (( ${#files[@]} == 0 )); then
        echo "No *.$file_extension files in $subdirectory" >&2
        return 1
    fi

    echo "Files in '$subdirectory' (.$file_extension):"
    for i in "${!files[@]}"; do
        printf "  %2d) %s\n" "$((i+1))" "${files[$i]}"
    done

    # Loop until valid choice
    local choice
    while true; do
        read -rp "Select file number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#files[@]} )); then
            selected_file="${files[choice-1]}"
            echo "You selected: $selected_file"
            break
        fi
        echo "Invalid selection. Try again."
    done
}

# End of file_utils.sh
