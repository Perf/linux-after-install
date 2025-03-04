#!/usr/bin/env bash

# Communication & Collaboration Tools module
# Contains functions for installing communication and collaboration tools

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

function install_slack() {
    local version
    version=$(curl -s "https://slack.com/release-notes/linux" 2>/dev/null | grep -m 1 -o -E "<h2>Slack [0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null | grep -m 1 -o -E "[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null)
    local url="https://downloads.slack-edge.com/desktop-releases/linux/x64/${version}/slack-desktop-${version}-amd64.deb"
    install_deb_package "$url" "Slack"
}

function install_discord() {
    local url="https://discord.com/api/download?platform=linux&format=deb"
    install_deb_package "$url" "Discord"
}

function install_zoom() {
    local url="https://zoom.us/client/latest/zoom_amd64.deb"
    install_deb_package "$url" "Zoom"
}

function install_anydesk() {
    log "INFO" "Starting AnyDesk installation"

    if prompt_user "yes_no" "Would you like to install AnyDesk?"; then
        (
            # Add the AnyDesk GPG key
            sudo apt update > /dev/null 2>&1
            sudo apt -y install ca-certificates curl apt-transport-https > /dev/null 2>&1
            sudo install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
            sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc > /dev/null 2>&1
            sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc > /dev/null 2>&1

            # Add the AnyDesk apt repository
            echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null

            # Update apt caches and install the AnyDesk client
            sudo apt update > /dev/null 2>&1
            sudo apt -y install anydesk > /dev/null 2>&1
        ) & show_progress $! "Installing AnyDesk"
        log "INFO" "AnyDesk installed successfully"
    else
        log "INFO" "AnyDesk installation skipped"
    fi
}
