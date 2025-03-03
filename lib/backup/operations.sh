#!/usr/bin/env bash
# Backup operation functions

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/ui.sh"

# Function to check if process is running
function check_process() {
    local process_name=$1
    if pgrep -x "$process_name" > /dev/null; then
        print_message "$RED" "WARNING: $process_name is still running. Please close it before proceeding."
        return 1
    fi
    return 0
}

# Function to backup a directory if it exists
function backup_if_exists() {
    local src=$1
    local dest=$2
    if [ -e "$src" ]; then
        log "INFO" "Backing up $src"
        mkdir -p "$(dirname "$dest")"
        cp -rp "$src" "$dest"
    else
        log "WARN" "Warning: $src does not exist, skipping..."
    fi
}

# Function to backup an application
function backup_app() {
    local app_name=$1
    local process_name=$2
    local paths=$3

    # Check if process is running
    if ! check_process "$process_name"; then
        log "ERROR" "$app_name is still running. Please close it first."
        return 1
    fi

    # Process paths
    log "INFO" "Processing $app_name..."
    IFS=';' read -ra path_array <<< "$paths"
    for path in "${path_array[@]}"; do
        backup_if_exists "$path" "${BACKUP_DIR}${path#$HOME}"
    done

    return 0
}

# Global array for storing selected backup items
declare -a SELECTED_BACKUPS=()

# Function to set selected backup items
function set_selected_backups() {
    SELECTED_BACKUPS=("$@")
}

# Function to get selected backup items
function get_selected_backups() {
    echo "${SELECTED_BACKUPS[@]}"
}

# Function to check running processes
function check_running_processes() {
    local -a processes=("$@")
    local running_count=0

    # Check each process
    for process in "${processes[@]}"; do
        if ! check_process "$process"; then
            running_count=$((running_count + 1))
        fi
    done

    return $running_count
}

# Function to create backup name with timestamp
function create_backup_name() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="app_backup_${timestamp}"
    local backup_archive="${backup_dir}.tar.gz"
    
    echo "$backup_dir:$backup_archive"
}

# Function to backup selected items
function backup_selected_items() {
    local backup_dir=$1
    
    # Process selected items
    for item in "${SELECTED_BACKUPS[@]}"; do
        if [[ "$item" == CONFIG:* ]]; then
            # Process CONFIG items
            local config="${item#CONFIG:}"
            backup_if_exists "$config" "${backup_dir}${config#$HOME}"
        else
            # Process APP items
            IFS=':' read -r app_name process paths <<< "$item"
            backup_app "$app_name" "$process" "$paths"
        fi
    done
}

# Function to perform the actual backup
function perform_backup() {
    local backup_dir=$1
    local backup_archive=$2

    # Create timestamp for backup name if not provided
    if [[ -z "$backup_dir" ]]; then
        local backup_info
        backup_info=$(create_backup_name)
        IFS=':' read -r backup_dir backup_archive <<< "$backup_info"
    fi

    # Ensure backup dir is set
    BACKUP_DIR="$backup_dir"

    if [ ${#SELECTED_BACKUPS[@]} -eq 0 ]; then
        log "WARN" "No items selected for backup. Exiting."
        return 1
    fi

    # Create backup directory
    log "INFO" "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"

    # Check if required apps are running
    log "INFO" "Checking for running applications..."
    
    # Extract processes to check
    local app_to_check=()
    for item in "${SELECTED_BACKUPS[@]}"; do
        if [[ "$item" == CONFIG:* ]]; then
            # Skip CONFIG items for process check
            continue
        fi

        # Extract process name from app entry
        IFS=':' read -r app_name process _ <<< "$item"
        app_to_check+=("$process")
    done

    # Remove duplicates
    app_to_check=($(printf "%s\n" "${app_to_check[@]}" | sort -u))

    # Check for running processes
    if ! check_running_processes "${app_to_check[@]}"; then
        log "ERROR" "Please close all applications before proceeding."
        log "ERROR" "Then run this script again."
        return 1
    fi

    # Backup selected items
    log "INFO" "Starting backup process..."
    backup_selected_items "$BACKUP_DIR"

    # Create tar archive with permissions preserved
    log "INFO" "Creating backup archive..."
    tar -czpf "$backup_archive" "$BACKUP_DIR"

    # Cleanup temporary directory
    log "INFO" "Cleaning up temporary files..."
    rm -rf "$BACKUP_DIR"

    # Show completion message
    log "INFO" "Backup complete! Archive created: $backup_archive"
    print_message "$YELLOW" "To restore on the new system, use:"
    echo "tar -xzpf $backup_archive -C \$HOME"
    log "INFO" "Note: Make sure to close all applications before restoring."

    # Show backup size
    local BACKUP_SIZE
    BACKUP_SIZE=$(du -h "$backup_archive" | cut -f1)
    log "INFO" "Backup size: $BACKUP_SIZE"

    return 0
}
