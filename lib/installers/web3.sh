#!/usr/bin/env bash

# Web3 Tools module
# Contains functions for installing Web3-related tools

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

function install_ledger_live() {
    log "INFO" "Starting Ledger Live installation"

    if prompt_user "yes_no" "Would you like to install Ledger Live?"; then
        (
            wget https://download.live.ledger.com/latest/linux -q -O ~/bin/ledger-live-desktop.AppImage 2>/dev/null
            chmod +x ~/bin/ledger-live-desktop.AppImage > /dev/null 2>&1
            cp .local/share/applications/LedgerLive.desktop ~/.local/share/applications/LedgerLive.desktop > /dev/null 2>&1
            update-desktop-database ~/.local/share/applications > /dev/null 2>&1
            xdg-mime default LedgerLive.desktop x-scheme-handler/ledgerlive > /dev/null 2>&1
        ) & show_progress $! "Installing Ledger Live"
        log "INFO" "Ledger Live installed successfully"
    else
        log "INFO" "Ledger Live installation skipped"
    fi
}

function install_ledger_udev_rules() {
    log "INFO" "Starting Ledger udev rules installation"

    if prompt_user "yes_no" "Would you like to install Ledger udev rules?"; then
        (
            wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh 2>/dev/null | sudo bash > /dev/null 2>&1
        ) & show_progress $! "Installing Ledger udev rules"
        log "INFO" "Ledger udev rules installed successfully"
    else
        log "INFO" "Ledger udev rules installation skipped"
    fi
}