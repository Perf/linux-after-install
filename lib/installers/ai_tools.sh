#!/usr/bin/env bash

# AI Tools module
# Contains functions for installing AI-related tools

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

function install_claude_code() {
    log "INFO" "Starting Claude Code installation"

    if prompt_user "yes_no" "Would you like to install Claude Code?"; then
        (
            # Download and run the official installer
            curl -fsSL https://claude.ai/claude-code/install.sh | bash
        ) & show_progress $! "Installing Claude Code"
        log "INFO" "Claude Code installed successfully"
        log "INFO" "Run 'claude' to start using Claude Code"
    else
        log "INFO" "Claude Code installation skipped"
    fi
}

function install_goose_cli() {
    log "INFO" "Starting Goose CLI installation"

    if prompt_user "yes_no" "Would you like to install Goose CLI?"; then
        (
            curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash
        ) & show_progress $! "Installing Goose CLI"
        log "INFO" "Goose CLI installed successfully"
        log "INFO" "please run 'goose configure' after..."
    else
        log "INFO" "Goose CLI installation skipped"
    fi
}

function install_windsurf_ide() {
    log "INFO" "Starting Windsurf IDE installation"

    if prompt_user "yes_no" "Would you like to install Windsurf IDE? (Codeium's open source AI coding assistant)"; then
        (
            # Add the repository to sources.list.d
            curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg > /dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null
            
            # Update package lists
            sudo apt-get update > /dev/null 2>&1
            
            # Install Windsurf
            sudo apt-get -y install windsurf > /dev/null 2>&1
        ) & show_progress $! "Installing Windsurf IDE"
        log "INFO" "Windsurf IDE installed successfully"
        log "INFO" "Run 'windsurf' to start using Windsurf IDE"
    else
        log "INFO" "Windsurf IDE installation skipped"
    fi
}

function install_cursor_ide() {
    log "INFO" "Starting Cursor IDE installation"

    if prompt_user "yes_no" "Would you like to install Cursor IDE?\nRead https://cursor.sh/ for details."; then
        (
            # Download the latest .deb package
            wget -q "https://download.cursor.sh/linux/appImage/x64/Cursor-latest.deb" -O _cursor.deb 2>/dev/null

            # Install the package
            sudo dpkg -i _cursor.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1

            # Cleanup
            rm _cursor.deb > /dev/null 2>&1

        ) & show_progress $! "Installing Cursor IDE"
        log "INFO" "Cursor IDE installed successfully"
    else
        log "INFO" "Cursor IDE installation skipped"
    fi
}