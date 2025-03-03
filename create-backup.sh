#!/usr/bin/env bash

# Set error handling
set -euo pipefail

# Source necessary libraries
source ./lib/core/utils.sh
source ./lib/core/ui.sh
source ./lib/core/menu.sh
source ./lib/backup/operations.sh

# Function to process backup selections
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

# Function to prepare backup menu
function prepare_backup_menu() {
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

    # Show menu and process selections
    process_menu_selections "Select Items to Backup" BACKUP_DISPLAY_NAMES BACKUP_FUNCTION_NAMES BACKUP_RECOMMENDED process_backup_selections
}

# Function to run backup process
function run_backup() {
    # Prepare and show the backup menu
    prepare_backup_menu

    # Create backup name
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="app_backup_${timestamp}"
    local backup_archive="${backup_dir}.tar.gz"

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
    # Load backup configurations directly
    source "./config/backup.conf"

    # Check if variables were loaded correctly
    if [[ ${#BACKUP_APPS[@]} -eq 0 ]]; then
        log "ERROR" "No applications defined in backup configuration"
        exit 1
    fi

    if [[ ${#BACKUP_CONFIGS[@]} -eq 0 ]]; then
        log "WARN" "No configuration files defined in backup configuration"
    fi

    log "INFO" "Loaded backup configuration with ${#BACKUP_APPS[@]} apps and ${#BACKUP_CONFIGS[@]} configs"

    # Show welcome message
    show_backup_welcome_message

    # Run backup loop
    local continue_backup=true
    while $continue_backup; do
        # Run backup process
        run_backup

        # Ask if user wants to create another backup
        if prompt_user "yes_no" "Would you like to create another backup?"; then
            clear
            echo "Creating another backup..."
        else
            continue_backup=false
        fi
    done

    echo "Exiting backup script. Goodbye!"
    exit 0
}

# Run main program
main "$@"
