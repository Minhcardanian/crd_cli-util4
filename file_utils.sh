source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"
select_poolid() {
    # Fetch the list of pool IDs from the $CARDANO_CLI command
    pools=$($CARDANO_CLI query stake-pools $NETWORK 2>/dev/null)

    # Check if the command ran successfully
    if [[ $? -ne 0 || -z "$pools" ]]; then
        echo "Unable to fetch the pool list. Please check your $CARDANO_CLI setup or the network connection."
        exit 1
    fi

    # Display the list of pool IDs with numbering
    echo "List of available pool IDs:"
    IFS=$'\n' read -r -d '' -a pool_list <<< "$pools"
    for i in "${!pool_list[@]}"; do
        echo "$((i + 1)). ${pool_list[$i]}"
    done

    # Prompt the user to select a pool
    while true; do
        read -rp "Enter the number of the pool you want to select: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#pool_list[@]} ]]; then
            POOL_ID="${pool_list[$((choice - 1))]}"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    # Display the selected pool ID
    echo "You have selected Pool ID: $POOL_ID"
}


select_file() {
    local subdirectory=$1
    local file_extension=$2

    # Check if the subdirectory exists
    if [[ ! -d "$subdirectory" ]]; then
        echo "Subdirectory '$subdirectory' does not exist."
        exit 1
    fi

    # Find files with the given extension in the subdirectory
    local files=($(ls "$subdirectory"/*.$file_extension 2>/dev/null))

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No *.$file_extension files found in the '$subdirectory' directory."
        exit 1
    fi

    # Display the list of files
    echo "Select a $file_extension file in the '$subdirectory' directory:"
    for i in "${!files[@]}"; do
        echo "$((i+1)). ${files[$i]}"
    done

    # Prompt the user to select a file
    read -p "Enter the number corresponding to the file you want to select: " choice
    selected_file="${files[$((choice - 1))]}"
    echo "You have selected: $selected_file"
}

# Example usage:
# select_file "subdirectory_name" "file_extension"
