#!/usr/bin/env bash

# Communication & Collaboration Tools module
# Contains functions for installing communication and collaboration tools

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

function install_slack() {
    log "INFO" "Starting Slack installation"

    if prompt_user "yes_no" "Would you like to install Slack?"; then
        (
            local SLACK_VERSION
            SLACK_VERSION=$(curl -s "https://slack.com/release-notes/linux" 2>/dev/null | grep -m 1 -o -E "<h2>Slack [0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null | grep -m 1 -o -E "[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null)
            wget -q "https://downloads.slack-edge.com/desktop-releases/linux/x64/${SLACK_VERSION}/slack-desktop-${SLACK_VERSION}-amd64.deb" -O _slack.deb 2>/dev/null
            sudo dpkg -i _slack.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
            rm _slack.deb > /dev/null 2>&1
        ) & show_progress $! "Installing Slack"
        log "INFO" "Slack installed successfully"
    else
        log "INFO" "Slack installation skipped"
    fi
}

function install_discord() {
    log "INFO" "Starting Discord installation"

    if prompt_user "yes_no" "Would you like to install Discord?"; then
        (
            wget -q "https://discord.com/api/download?platform=linux&format=deb" -O _discord.deb 2>/dev/null
            sudo dpkg -i _discord.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
            rm _discord.deb > /dev/null 2>&1
        ) & show_progress $! "Installing Discord"
        log "INFO" "Discord installed successfully"
    else
        log "INFO" "Discord installation skipped"
    fi
}

function install_zoom() {
    log "INFO" "Starting Zoom installation"

    if prompt_user "yes_no" "Would you like to install Zoom?"; then
        (
            wget -q https://zoom.us/client/latest/zoom_amd64.deb 2>/dev/null
            sudo dpkg -i zoom_amd64.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
            rm zoom_amd64.deb > /dev/null 2>&1
        ) & show_progress $! "Installing Zoom"
        log "INFO" "Zoom installed successfully"
    else
        log "INFO" "Zoom installation skipped"
    fi
}

function install_anydesk() {
    log "INFO" "Starting AnyDesk installation"

    if prompt_user "yes_no" "Would you like to install AnyDesk?"; then
        (
            # Add the AnyDesk GPG key
            sudo apt update > /dev/null 2>&1
            sudo apt -y install ca-certificates wget > /dev/null 2>&1
            sudo install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
            wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg 2>/dev/null
            sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc > /dev/null 2>&1

            # Add the AnyDesk apt repository
            printf "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list > /dev/null

            # Update apt caches and install the AnyDesk client
            sudo apt update > /dev/null 2>&1
            sudo apt -y install anydesk > /dev/null 2>&1
        ) & show_progress $! "Installing AnyDesk"
        log "INFO" "AnyDesk installed successfully"
    else
        log "INFO" "AnyDesk installation skipped"
    fi
}

function install_transgui() {
    log "INFO" "Starting Transmission Remote GUI installation"

    if prompt_user "yes_no" "Would you like to install Transmission Remote GUI?"; then
        (
            sudo apt -y install transgui > /dev/null 2>&1
        ) & show_progress $! "Installing Transmission Remote GUI"
        log "INFO" "Transmission Remote GUI installed successfully"
    else
        log "INFO" "Transmission Remote GUI installation skipped"
    fi
}