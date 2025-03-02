#!/usr/bin/env bash

# Terminal Customization module
# Contains functions for customizing terminal appearance and functionality

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

function install_terminal_tools() {
    log "INFO" "Starting terminal tools installation"
    
    if prompt_user "yes_no" "Would you like to install terminal tools and utilities?"; then
        (
            sudo apt -y install fontconfig mc vim git socat konsole yakuake powerline > /dev/null 2>&1
        ) & show_progress $! "Installing terminal tools"
        log "INFO" "Terminal tools installed successfully"
    else
        log "INFO" "Terminal tools installation skipped"
    fi
}

function install_nerd_fonts() {
    log "INFO" "Starting Nerd Fonts installation"
    
    if prompt_user "yes_no" "Would you like to install Mononoki Nerd Font?"; then
        (
            # Create fonts directory if it doesn't exist
            FONT_DIR="$HOME/.local/share/fonts"
            mkdir -p "$FONT_DIR"
            
            # Create temporary directory for download
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            # Get the latest release version from GitHub API
            LATEST_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "tag_name" | cut -d'"' -f4)
            if [ -z "$LATEST_VERSION" ]; then
                log "ERROR" "Could not determine latest Nerd Fonts version"
                return 1
            fi
            
            # Download Mononoki font
            FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/Mononoki.zip"
            wget -q "$FONT_URL" 
            unzip -q Mononoki.zip -d "$FONT_DIR/Mononoki"
            cd - > /dev/null
            rm -rf "$TEMP_DIR"
            fc-cache -f > /dev/null 2>&1
            
            # Set as default monospace font if KDE is available
            if command -v kwriteconfig5 > /dev/null 2>&1; then
                kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed "Mononoki Nerd Font,12,-1,5,50,0,0,0,0,0,Regular"
            fi
        ) & show_progress $! "Installing Mononoki Nerd Font"
        
        if fc-list | grep -i "Mononoki" > /dev/null; then
            log "INFO" "Mononoki Nerd Font installed successfully"
        else
            log "WARN" "Font installation may have failed"
        fi
    else
        log "INFO" "Nerd Fonts installation skipped"
    fi
}

function install_starship_prompt() {
    log "INFO" "Starting Starship prompt installation"
    
    if prompt_user "yes_no" "Would you like to install Starship prompt?"; then
        (
            # Install Starship
            curl -sS https://starship.rs/install.sh | sh > /dev/null 2>&1
            
            # Create backup of existing .bashrc
            if [ -f ~/.bashrc ]; then
                cp ~/.bashrc ~/.bashrc.bak
            fi
            
            # Add starship init to ~/.bashrc if not already present
            if ! grep -q "starship init bash" ~/.bashrc; then
                echo 'eval "$(starship init bash)"' >> ~/.bashrc
            fi
            
            # Setup gruvbox-rainbow preset
            mkdir -p ~/.config
            starship preset gruvbox-rainbow -o ~/.config/starship.toml > /dev/null 2>&1
        ) & show_progress $! "Installing Starship prompt"
        log "INFO" "Starship prompt installed successfully"
    else
        log "INFO" "Starship prompt installation skipped"
    fi
}

function make_terminal_sexy() {
    log "INFO" "Starting terminal customization"
    
    install_terminal_tools
    install_nerd_fonts
    install_starship_prompt
    
    log "INFO" "Terminal customization completed"
}