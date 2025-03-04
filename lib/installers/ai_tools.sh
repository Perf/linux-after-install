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
            local version
            version=$(curl --silent 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' 2>/dev/null | jq '.tag_name' -r 2>/dev/null)
            curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash
            \. "$HOME/.nvm/nvm.sh"
            nvm install --lts
            npm install -g @anthropic-ai/claude-code
        ) & show_progress $! "Installing Claude Code"
        log "INFO" "Claude Code installed successfully"
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
    local url="https://download.cursor.sh/linux/appImage/x64/Cursor-latest.deb"
    install_deb_package "$url" "Cursor IDE"
}
