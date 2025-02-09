#!/bin/bash

# Directory to scan (default is home directory)
SCAN_DIR="$HOME"

# Common configuration directories to check
CONFIG_DIRS=(".config" ".cache" ".local/share" ".local/state")

# Get list of installed packages
get_installed_packages() {
    # Try different package managers
    if command -v dpkg >/dev/null; then
        dpkg -l | awk '/^ii/ {print $2}' | cut -d: -f1
    elif command -v rpm >/dev/null; then
        rpm -qa
    elif command -v pacman >/dev/null; then
        pacman -Qq
    fi
}

# Function to check if a directory might be related to an installed package
is_orphaned_dir() {
    local dir_name="$1"
    local base_name=$(basename "$dir_name" | tr '[:upper:]' '[:lower:]')

    # Skip certain directories that should always be kept
    local skip_dirs=("ssh" "gnupg" "mozilla" "chrome" "chromium" "google-chrome" "tor" "vim" "emacs" "nano")
    for skip in "${skip_dirs[@]}"; do
        if [[ "$base_name" == "$skip" ]]; then
            return 1
        fi
    done

    # Check against installed packages
    while read -r pkg; do
        pkg_name=$(echo "$pkg" | tr '[:upper:]' '[:lower:]')
        if [[ "$base_name" == *"$pkg_name"* ]] || [[ "$pkg_name" == *"$base_name"* ]]; then
            return 1
        fi
    done < <(get_installed_packages)

    return 0
}

# Function to get directory size
get_dir_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

echo "Scanning for potentially orphaned configuration directories..."
echo "This may take a while depending on the number of directories..."
echo

# Process each config directory
for config_dir in "${CONFIG_DIRS[@]}"; do
    full_path="$SCAN_DIR/$config_dir"

    if [ -d "$full_path" ]; then
        echo "Checking $config_dir..."

        # Find all immediate subdirectories
        while IFS= read -r dir; do
            if [ -d "$dir" ] && is_orphaned_dir "$dir"; then
                size=$(get_dir_size "$dir")
                echo "  Potentially orphaned: $dir (Size: $size)"
            fi
        done < <(find "$full_path" -maxdepth 1 -type d ! -name "$(basename "$full_path")")
    fi
done

echo
echo "Note: This script provides suggestions only. Please verify before removing any directories."
echo "Some configuration directories might be intentionally kept for future use."
