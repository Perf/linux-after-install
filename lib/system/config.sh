#!/usr/bin/env bash

# System configuration module
# Contains functions for configuring system-level settings

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"

function set_hostname() {
    local old_hostname
    old_hostname=$(hostname 2>/dev/null)

    log "INFO" "Starting hostname configuration"

    if ! prompt_user "yes_no" "Would you like to change the system hostname? Current: '$old_hostname'"; then
        log "INFO" "Hostname change skipped by user"
        return 0
    fi

    # Get new hostname from user
    prompt_user "input" "Enter new hostname" "$old_hostname"
    local new_hostname
    new_hostname="$REPLY"

    if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9-]+$ ]]; then
        log "ERROR" "Invalid hostname format. Hostname can only contain letters, numbers, and hyphens."
        return 1
    fi

    if [[ "$new_hostname" == "$old_hostname" ]]; then
        log "INFO" "Hostname unchanged"
        return 0
    fi

    printf "\nHostname changes to be applied:\n"
    printf "  Current: %s\n" "$old_hostname"
    printf "  New: %s\n" "$new_hostname"

    if prompt_user "yes_no" "Apply these changes?"; then
        (
            sudo hostnamectl set-hostname "$new_hostname" > /dev/null 2>&1 &&
            sudo sed -i "s/127\.0\.1\.1\s.*/127.0.1.1\t${new_hostname}/" /etc/hosts > /dev/null 2>&1
        ) & show_progress $! "Updating hostname"

        if [[ "$(hostname 2>/dev/null)" == "$new_hostname" ]]; then
            log "INFO" "Hostname successfully changed to '$new_hostname'"
            return 0
        else
            log "ERROR" "Failed to change hostname"
            return 1
        fi
    else
        log "INFO" "Hostname change cancelled by user"
        return 0
    fi
}

function remove_snapd() {
    log "INFO" "Starting snapd removal process"

    local installed_snaps
    installed_snaps=$(snap list 2>/dev/null | awk 'NR>1 {print $1}')

    # Show current status
    if [[ -n "$installed_snaps" ]]; then
        local message="The following snap packages are installed and will be removed:\n$installed_snaps"
    else
        local message="No snap packages are currently installed"
    fi
    message+="\n\n⚠️  Warning: This will completely remove snapd and all snap packages."

    if ! prompt_user "yes_no" "$message"; then
        log "INFO" "Snapd removal cancelled"
        return 0
    fi

    (
        log "INFO" "Stopping snapd services"
        sudo systemctl stop snapd.service snapd.socket snapd.seeded.service > /dev/null 2>&1

        log "INFO" "Removing snap packages"
        for snap in $(snap list 2>/dev/null | awk 'NR>1 {print $1}'); do
            log "INFO" "Removing snap package: $snap"
            sudo snap remove --purge "$snap" > /dev/null 2>&1
        done

        # Wait for snap processes
        while pgrep -a snap >/dev/null 2>&1; do
            sleep 1
        done

        log "INFO" "Unmounting snap volumes"
        for mnt in $(mount | grep snapd | cut -d' ' -f3 2>/dev/null); do
            sudo umount -l "$mnt" > /dev/null 2>&1 || true
        done

        log "INFO" "Removing snapd package and configuration"
        sudo apt -y remove --purge snapd > /dev/null 2>&1
        sudo apt -y autoremove --purge > /dev/null 2>&1

        log "INFO" "Removing snap directories and cache"
        sudo rm -rf \
            /var/cache/snapd/ \
            /var/lib/snapd/ \
            /var/snap/ \
            /snap/ \
            ~/snap/ > /dev/null 2>&1

        log "INFO" "Removing remaining configuration"
        sudo rm -rf \
            /etc/snap/ \
            /usr/lib/snapd/ \
            /usr/share/snapd/ \
            /usr/share/keyrings/snapd.gpg > /dev/null 2>&1

        log "INFO" "Configuring system to prevent snapd reinstallation"
        sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -1
EOF

        # Handle Firefox replacement if needed
        if ! command -v firefox >/dev/null 2>&1 && prompt_user "yes_no" "Would you like to re-install Firefox from Mozilla PPA?"; then
            log "INFO" "Installing Firefox from Mozilla PPA"
            sudo add-apt-repository -y ppa:mozillateam/ppa > /dev/null 2>&1
            sudo tee /etc/apt/preferences.d/mozilla-firefox > /dev/null <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
            sudo apt update > /dev/null 2>&1
            sudo apt install -y firefox > /dev/null 2>&1
        fi

    ) & show_progress $! "Removing snapd and related components"

    log "INFO" "Snapd removal completed successfully"
    printf "\n💡 System changes made:\n"
    printf "   - All snap packages removed\n"
    printf "   - Snapd service and socket disabled\n"
    printf "   - Snapd package and configuration removed\n"
    printf "   - Snap directories cleaned up\n"
    printf "   - System configured to prevent snapd reinstallation\n"
    if command -v firefox >/dev/null 2>&1; then
        printf "   - Firefox installed from Mozilla PPA\n"
    fi
}

function set_swappiness() {
    local new_swappiness=10
    local old_swappiness
    old_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)

    log "INFO" "Starting swappiness configuration"

    local message="Configure system swappiness?\nCurrent: $old_swappiness\nRecommended: $new_swappiness"
    local options="Use recommended ($new_swappiness),Keep current ($old_swappiness),Enter custom value"
    prompt_user "choice" "$message" "" "$options"
    local choice="$REPLY"

    case $choice in
        1) # Use recommended
            ;;
        2) # Keep current
            new_swappiness="$old_swappiness"
            ;;
        3) # Custom value
            prompt_user "input" "Enter custom swappiness value" "$old_swappiness"
            new_swappiness="$REPLY"
            ;;
    esac

    if [[ "$new_swappiness" != "$old_swappiness" ]]; then
        (
            printf "vm.swappiness = %d" "$new_swappiness" | sudo tee /etc/sysctl.d/swapiness.conf > /dev/null
            sudo sysctl -p --system > /dev/null 2>&1
        ) & show_progress $! "Updating swappiness"
        log "INFO" "Swappiness updated to $new_swappiness"
    else
        log "INFO" "Swappiness unchanged"
    fi
}

function add_oibaf_repo() {
    log "INFO" "Starting Oibaf graphics drivers repository configuration"

    local message="Would you like to add Oibaf graphics drivers repository?\nRead https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers for details."

    if prompt_user "yes_no" "$message"; then
        (
            sudo add-apt-repository -y ppa:oibaf/graphics-drivers > /dev/null 2>&1
        ) & show_progress $! "Adding Oibaf repository"
        log "INFO" "Oibaf repository added successfully"
    else
        log "INFO" "Oibaf repository installation skipped"
    fi
}

function add_kubuntu_backports_repo() {
    log "INFO" "Starting Kubuntu Backports repository configuration"

    local message="Would you like to add Kubuntu Backports repository?\nRead https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports for details."

    if prompt_user "yes_no" "$message"; then
        (
            sudo add-apt-repository -y ppa:kubuntu-ppa/backports > /dev/null 2>&1
        ) & show_progress $! "Adding Kubuntu Backports repository"
        log "INFO" "Kubuntu Backports repository added successfully"
    else
        log "INFO" "Kubuntu Backports repository installation skipped"
    fi
}

function perform_system_update() {
    log "INFO" "Starting full system update"
    
    if prompt_user "yes_no" "Would you like to perform a full system update?"; then
        (
            sudo apt -y update > /dev/null 2>&1
            sudo apt -y full-upgrade > /dev/null 2>&1
        ) & show_progress $! "Updating system packages"
        log "INFO" "System update completed successfully"
    else
        log "INFO" "System update skipped"
    fi
}

function install_common_utilities() {
    log "INFO" "Starting installation of common utilities"
    
    if prompt_user "yes_no" "Would you like to install common utility packages?"; then
        (
            sudo apt -y install \
                software-properties-common \
                build-essential \
                htop \
                jq \
                wget \
                curl \
                inxi \
                apt-transport-https \
                fwupd-signed > /dev/null 2>&1
        ) & show_progress $! "Installing common utilities"
        log "INFO" "Common utilities installed successfully"
    else
        log "INFO" "Common utilities installation skipped"
    fi
}

function disable_kde_baloo() {
    log "INFO" "Starting KDE Baloo indexer configuration"
    
    if prompt_user "yes_no" "Would you like to disable the KDE Baloo file indexer? (Improves performance)"; then
        (
            balooctl disable > /dev/null 2>&1
            balooctl purge > /dev/null 2>&1
        ) & show_progress $! "Disabling KDE Baloo indexer"
        log "INFO" "KDE Baloo indexer disabled successfully"
    else
        log "INFO" "KDE Baloo indexer configuration skipped"
    fi
}

function perform_cleanup() {
    log "INFO" "Starting system cleanup"
    
    if prompt_user "yes_no" "Would you like to clean up package caches and remove unused packages?"; then
        (
            sudo apt -y autoclean > /dev/null 2>&1
            sudo apt -y autoremove > /dev/null 2>&1
        ) & show_progress $! "Cleaning up system"
        log "INFO" "System cleanup completed successfully"
    else
        log "INFO" "System cleanup skipped"
    fi
}