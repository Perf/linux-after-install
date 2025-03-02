#!/usr/bin/env bash

# Set error handling
set -euo pipefail

# Source necessary libraries
source ./lib/core/utils.sh
source ./lib/core/ui.sh
source ./lib/core/menu.sh
source ./lib/backup/operations.sh

# Load backup configurations
if ! load_backup_configs "./config/backup.conf"; then
    exit 1
fi

# Reconstruct arrays from exported environment variables
declare -a BACKUP_APPS=()
declare -a BACKUP_CONFIGS=()

if [[ -n "$BACKUP_APPS_SIZE" ]]; then
    for ((i=0; i<BACKUP_APPS_SIZE; i++)); do
        varname="BACKUP_APP_$i"
        BACKUP_APPS+=("${!varname}")
    done
fi

if [[ -n "$BACKUP_CONFIGS_SIZE" ]]; then
    for ((i=0; i<BACKUP_CONFIGS_SIZE; i++)); do
        varname="BACKUP_CONFIG_$i"
        BACKUP_CONFIGS+=("${!varname}")
    done
fi

# Arrays have been successfully reconstructed
log "INFO" "Loaded backup configuration with ${#BACKUP_APPS[@]} apps and ${#BACKUP_CONFIGS[@]} configs"

# Function to process backup selections
# shellcheck disable=SC2317
function process_backup_selections() {
    local selected_functions=$1
    local selected_items=()

    # Process the selected functions
    for func in $selected_functions; do
        # Parse the function name to get the type and index
        if [[ "$func" =~ ^item_([0-9]+)$ ]]; then
            # It's an BACKUP_APPS item
            local index="${BASH_REMATCH[1]}"
            selected_items+=("${BACKUP_APPS[$index]}")
        elif [[ "$func" =~ ^config_([0-9]+)$ ]]; then
            # It's a BACKUP_CONFIGS item
            local index="${BASH_REMATCH[1]}"
            selected_items+=("CONFIG:${BACKUP_CONFIGS[$index]}")
        fi
    done

    # Set selected backup items
    set_selected_backups "${selected_items[@]}"
}

# Function to run backup process
function run_backup() {
    # Create timestamp for backup name
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="app_backup_${timestamp}"
    local backup_archive="${backup_dir}.tar.gz"

    # Create arrays for the menu
    declare -a BACKUP_DISPLAY_NAMES=()
    declare -a BACKUP_FUNCTION_NAMES=()
    declare -a BACKUP_RECOMMENDED=()

    # Add applications
    for i in "${!BACKUP_APPS[@]}"; do
        # Extract app name from the app entry
        IFS=':' read -r app_name _ _ <<< "${BACKUP_APPS[$i]}"
        BACKUP_DISPLAY_NAMES+=("$app_name")
        BACKUP_FUNCTION_NAMES+=("item_$i")
        BACKUP_RECOMMENDED+=(1)  # All are recommended by default
    done

    # Add config files
    for i in "${!BACKUP_CONFIGS[@]}"; do
        # Get directory for display
        config_name="${BACKUP_CONFIGS[$i]}"
        BACKUP_DISPLAY_NAMES+=("$config_name")
        BACKUP_FUNCTION_NAMES+=("config_$i")
        BACKUP_RECOMMENDED+=(1)  # All are recommended by default
    done

    # Display instructions
    printf "\nSelect which items you want to backup:\n"
    printf "   - Applications will be checked to ensure they're not running before backup\n"
    printf "   - Configuration files will be backed up as-is\n\n"
    sleep 1

    # Convert arrays to serialized strings to pass to subprocesses
    local serialized_display_names=""
    local serialized_function_names=""
    local serialized_recommended=""

    for ((i=0; i<${#BACKUP_DISPLAY_NAMES[@]}; i++)); do
        # Escape any special characters with base64 encoding
        local encoded_name=$(echo "${BACKUP_DISPLAY_NAMES[$i]}" | base64)
        serialized_display_names+="$encoded_name;"
    done

    for ((i=0; i<${#BACKUP_FUNCTION_NAMES[@]}; i++)); do
        serialized_function_names+="${BACKUP_FUNCTION_NAMES[$i]};"
    done

    for ((i=0; i<${#BACKUP_RECOMMENDED[@]}; i++)); do
        serialized_recommended+="${BACKUP_RECOMMENDED[$i]};"
    done

    # Export these as environment variables to be available to subprocesses
    export MENU_DISPLAY_NAMES="$serialized_display_names"
    export MENU_FUNCTION_NAMES="$serialized_function_names"
    export MENU_RECOMMENDED="$serialized_recommended"
    export MENU_ITEMS_COUNT="${#BACKUP_DISPLAY_NAMES[@]}"

    # Show menu and process selections
    process_menu_selections "Select Items to Backup" "MENU_DISPLAY_NAMES" "MENU_FUNCTION_NAMES" "MENU_RECOMMENDED" process_backup_selections

    # Perform the backup
    perform_backup "$backup_dir" "$backup_archive"

    return $?
}

# Function to show welcome message
function show_backup_welcome_message() {
    clear
    print_header "Application Backup Utility"

    echo -e "\nThis utility will help you backup your application data and configuration files."
    echo -e "The backup will be created as a compressed archive that you can easily transfer to a new system.\n"

    echo -e "Please follow these steps:"
    echo -e "1. Select the applications and configs you want to backup"
    echo -e "2. Close any running applications that will be backed up"
    echo -e "3. The backup archive will be created in the current directory\n"

    if prompt_user "yes_no" "Ready to proceed?"; then
        clear
        return 0
    else
        echo "Backup cancelled. Exiting."
        exit 1
    fi
}

# Main program
function main() {
    # Show welcome message
    show_backup_welcome_message

    # Run backup process
    run_backup

    # Ask if user wants to create another backup
    if prompt_user "yes_no" "Would you like to create another backup?"; then
        clear
        echo "Creating another backup..."
        run_backup
    fi

    echo "Exiting backup script. Goodbye!"
    exit 0
}

# Run main program
main "$@"
