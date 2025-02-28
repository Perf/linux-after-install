#!/bin/bash

# Set error handling
set -euo pipefail

# Create timestamp for backup name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="app_backup_${TIMESTAMP}"
BACKUP_ARCHIVE="${BACKUP_DIR}.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if process is running
check_process() {
    local process_name=$1
    if pgrep -x "$process_name" > /dev/null; then
        print_message "$RED" "WARNING: $process_name is still running. Please close it before proceeding."
        return 1
    fi
    return 0
}

# Function to backup a directory if it exists
backup_if_exists() {
    local src=$1
    local dest=$2
    if [ -e "$src" ]; then
        print_message "$GREEN" "Backing up $src"
        mkdir -p "$(dirname "$dest")"
        cp -rp "$src" "$dest"
    else
        print_message "$YELLOW" "Warning: $src does not exist, skipping..."
    fi
}

# Define applications and their backup paths
# Format: "app_name:process_name:path1;path2;path3"
declare -a APPS=(
    "Google Chrome:chrome:$HOME/.config/google-chrome;$HOME/.cache/google-chrome"
    "Microsoft Edge:msedge:$HOME/.config/microsoft-edge;$HOME/.cache/microsoft-edge"
    "Brave:brave:$HOME/.config/BraveSoftware;$HOME/.cache/BraveSoftware"
    "AWS VPN:vpn:$HOME/.config/AWSVPNClient"
    "AnyDesk:anydesk:$HOME/.anydesk"
    "Discord:discord:$HOME/.config/discord"
    "Studio 3T:studio3t:$HOME/.3T"
    "Transmission:transgui:$HOME/.config/Transmission Remote GUI"
    "Ledger Live:ledger-live:$HOME/.config/Ledger Live"
    "Claude Code:claude:$HOME/.claude.json"
    "Goose CLI:goose:$HOME/.config/goose"
)

# Define standalone config files and directories
declare -a CONFIGS=(
    "$HOME/.aws"
    "$HOME/.kube"
    "$HOME/.ssh"
    "$HOME/.bash_aliases"
    "$HOME/.vimrc"
)

# Create backup directory
print_message "$GREEN" "Creating backup directory..."
mkdir -p "$BACKUP_DIR"

# Check if required apps are running
print_message "$YELLOW" "Checking for running applications..."
RUNNING_PROCESSES=0

# Extract and check processes
for app in "${APPS[@]}"; do
    IFS=':' read -r app_name process paths <<< "$app"
    if ! check_process "$process"; then
        RUNNING_PROCESSES=$((RUNNING_PROCESSES + 1))
    fi
done

if [ $RUNNING_PROCESSES -gt 0 ]; then
    print_message "$RED" "Please close all applications before proceeding."
    print_message "$RED" "Then run this script again."
    exit 1
fi

# Backup application configs
print_message "$GREEN" "Starting backup process..."

# Process applications
for app in "${APPS[@]}"; do
    IFS=':' read -r app_name process paths <<< "$app"
    print_message "$GREEN" "Processing $app_name..."
    # Use ; as delimiter for paths
    IFS=';' read -ra path_array <<< "$paths"
    for path in "${path_array[@]}"; do
        backup_if_exists "$path" "${BACKUP_DIR}${path#$HOME}"
    done
done

# Process standalone configs
print_message "$GREEN" "Processing additional configurations..."
for config in "${CONFIGS[@]}"; do
    backup_if_exists "$config" "${BACKUP_DIR}${config#$HOME}"
done

# Create tar archive with permissions preserved
print_message "$GREEN" "Creating backup archive..."
tar -czpf "$BACKUP_ARCHIVE" "$BACKUP_DIR"

# Cleanup temporary directory
print_message "$GREEN" "Cleaning up temporary files..."
rm -rf "$BACKUP_DIR"

# Show completion message
print_message "$GREEN" "Backup complete! Archive created: $BACKUP_ARCHIVE"
print_message "$YELLOW" "To restore on the new system, use:"
echo "tar -xzpf $BACKUP_ARCHIVE -C \$HOME"
print_message "$YELLOW" "Note: Make sure to close all applications before restoring."

# Show backup size
BACKUP_SIZE=$(du -h "$BACKUP_ARCHIVE" | cut -f1)
print_message "$GREEN" "Backup size: $BACKUP_SIZE"
