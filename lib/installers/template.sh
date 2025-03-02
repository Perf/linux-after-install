#!/usr/bin/env bash
# Installation template functions

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# Function to install from apt repository
function install_apt_package() {
    local package_name=$1
    local display_name=$2
    
    log "INFO" "Starting $display_name installation"
    
    if prompt_user "yes_no" "Would you like to install $display_name?"; then
        (
            sudo apt -y install "$package_name" > /dev/null 2>&1
        ) & show_progress $! "Installing $display_name"
        log "INFO" "$display_name installed successfully"
    else
        log "INFO" "$display_name installation skipped"
    fi
}

# Function to install a deb package from URL
function install_deb_package() {
    local url=$1
    local display_name=$2
    
    log "INFO" "Starting $display_name installation"
    
    if prompt_user "yes_no" "Would you like to install $display_name?"; then
        (
            wget -q "$url" -O _temp.deb 2>/dev/null
            sudo dpkg -i _temp.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
            rm _temp.deb > /dev/null 2>&1
        ) & show_progress $! "Installing $display_name"
        log "INFO" "$display_name installed successfully"
    else
        log "INFO" "$display_name installation skipped"
    fi
}

# Function to install from PPA
function install_from_ppa() {
    local ppa=$1
    local package_name=$2
    local display_name=$3
    
    log "INFO" "Starting $display_name installation"
    
    if prompt_user "yes_no" "Would you like to install $display_name?"; then
        (
            sudo add-apt-repository -y "$ppa" > /dev/null 2>&1
            sudo apt update > /dev/null 2>&1
            sudo apt -y install "$package_name" > /dev/null 2>&1
        ) & show_progress $! "Installing $display_name"
        log "INFO" "$display_name installed successfully"
    else
        log "INFO" "$display_name installation skipped"
    fi
}

# Function to install AppImage
function install_appimage() {
    local url=$1
    local binary_name=$2
    local display_name=$3
    local desktop_file=$4  # Optional path to desktop file
    
    log "INFO" "Starting $display_name installation"
    
    if prompt_user "yes_no" "Would you like to install $display_name?"; then
        (
            # Ensure ~/bin directory exists
            mkdir -p ~/bin
            
            # Download AppImage
            wget -q "$url" -O ~/bin/"$binary_name".AppImage 2>/dev/null
            chmod +x ~/bin/"$binary_name".AppImage
            
            # Install desktop file if provided
            if [[ -n "$desktop_file" && -f "$desktop_file" ]]; then
                mkdir -p ~/.local/share/applications
                cp "$desktop_file" ~/.local/share/applications/
                update-desktop-database ~/.local/share/applications > /dev/null 2>&1
            fi
        ) & show_progress $! "Installing $display_name"
        log "INFO" "$display_name installed successfully (executable: $binary_name)"
    else
        log "INFO" "$display_name installation skipped"
    fi
}

# Function to install from GitHub release
function install_from_github() {
    local repo=$1
    local binary_name=$2
    local display_name=$3
    local asset_pattern=$4  # Optional pattern to match release asset
    
    log "INFO" "Starting $display_name installation"
    
    if prompt_user "yes_no" "Would you like to install $display_name?"; then
        (
            # Get latest release version
            local version
            version=$(curl --silent "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | 
                      grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            
            # Download and install based on asset pattern
            if [[ "$asset_pattern" == *.deb ]]; then
                # DEB package
                curl -sL "https://github.com/$repo/releases/download/$version/${asset_pattern/VERSION/$version}" -o _temp.deb
                sudo dpkg -i _temp.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
                rm _temp.deb > /dev/null 2>&1
            elif [[ "$asset_pattern" == *.tar.gz || "$asset_pattern" == *.tgz ]]; then
                # Tarball
                curl -sL "https://github.com/$repo/releases/download/$version/${asset_pattern/VERSION/$version}" | 
                tar -xz -C ~/bin
                chmod +x ~/bin/"$binary_name"
            else
                # Binary
                sudo curl -sL "https://github.com/$repo/releases/download/$version/${asset_pattern/VERSION/$version}" -o /usr/local/bin/"$binary_name"
                sudo chmod +x /usr/local/bin/"$binary_name"
            fi
        ) & show_progress $! "Installing $display_name"
        log "INFO" "$display_name installed successfully"
    else
        log "INFO" "$display_name installation skipped"
    fi
}