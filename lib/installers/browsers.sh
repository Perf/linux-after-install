#!/usr/bin/env bash
# Browser installation functions

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/template.sh"

# Function to install Google Chrome
function install_google_chrome() {
    local url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    install_deb_package "$url" "Google Chrome"
}

# Function to install Microsoft Edge
function install_microsoft_edge() {
    log "INFO" "Starting Microsoft Edge installation"
    
    if prompt_user "yes_no" "Would you like to install Microsoft Edge?"; then
        (
            # Add Microsoft Edge repository
            curl -s https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null | gpg --dearmor > microsoft.gpg 2>/dev/null
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ > /dev/null 2>&1
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list' 2>/dev/null
            sudo rm microsoft.gpg > /dev/null 2>&1
            
            # Install Edge
            sudo apt -y update > /dev/null 2>&1 && sudo apt -y install microsoft-edge-stable > /dev/null 2>&1
        ) & show_progress $! "Installing Microsoft Edge"
        log "INFO" "Microsoft Edge installed successfully"
    else
        log "INFO" "Microsoft Edge installation skipped"
    fi
}

# Function to install Brave Browser
function install_brave() {
    log "INFO" "Starting Brave browser installation"
    
    if prompt_user "yes_no" "Would you like to install Brave browser?"; then
        (
            # Add Brave repository
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 2>/dev/null
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
            
            # Install Brave
            sudo apt -y update > /dev/null 2>&1 && sudo apt -y install brave-browser > /dev/null 2>&1
        ) & show_progress $! "Installing Brave browser"
        log "INFO" "Brave browser installed successfully"
    else
        log "INFO" "Brave browser installation skipped"
    fi
}

# Function to install Transmission Remote GUI
function install_transgui() {
    install_apt_package "transgui" "Transmission Remote GUI"
}