#!/usr/bin/env bash

set -eu

# Helper function for logging
function log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%b] [%b] %b\n" "$timestamp" "$level" "$message" >&2
}

# Helper function for showing progress
function show_progress() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r[%b] %b..." "${spin:$i:1}" "$message"
        sleep 0.1
    done
    printf "\r✓ %b...done\n" "$message"
}

# Helper function for user prompt
function prompt_user() {
    local prompt_type="${1}"    # yes_no, choice, or input
    local message="${2}"
    local default="${3:-}"
    local options="${4:-}"        # For choice type

    # Display formatted message with visual separator
    printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "🔹 %b\n" "$message"

    case "$prompt_type" in
        "yes_no")
            printf "[Y/n]: "
            read -r answer
            [[ -z "$answer" || "${answer,,}" == "y"* ]] && return 0 || return 1
            ;;
        "choice")
            IFS=',' read -ra choices <<< "$options"
            for i in "${!choices[@]}"; do
                printf "%d) %b\n" $((i+1)) "${choices[$i]}"
            done
            printf "Choose [1-%d]: " "${#choices[@]}"
            read -r REPLY
            printf "%b" "$REPLY"
            ;;
        "input")
            if [[ -n "$default" ]]; then
                printf "[default: %s]: " "$default"
            else
                printf ": "
            fi
            read -r input
            REPLY="${input:-$default}"
            printf "%s" "$REPLY"
            ;;
    esac
}

# Functions

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

function install_google_chrome() {
    log "INFO" "Starting Google Chrome installation"

    if prompt_user "yes_no" "Would you like to install Google Chrome?"; then
        (
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O _google_chrome.deb 2>/dev/null
            sudo dpkg -i _google_chrome.deb > /dev/null 2>&1 || sudo apt -yf install > /dev/null 2>&1
            rm _google_chrome.deb > /dev/null 2>&1
        ) & show_progress $! "Installing Google Chrome"
        log "INFO" "Google Chrome installed successfully"
    else
        log "INFO" "Google Chrome installation skipped"
    fi
}

function install_microsoft_edge() {
    log "INFO" "Starting Microsoft Edge installation"

    if prompt_user "yes_no" "Would you like to install Microsoft Edge?"; then
        (
            curl -s https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null | gpg --dearmor > microsoft.gpg 2>/dev/null
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ > /dev/null 2>&1
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list' 2>/dev/null
            sudo rm microsoft.gpg > /dev/null 2>&1
            sudo apt -y update > /dev/null 2>&1 && sudo apt -y install microsoft-edge-stable > /dev/null 2>&1
        ) & show_progress $! "Installing Microsoft Edge"
        log "INFO" "Microsoft Edge installed successfully"
    else
        log "INFO" "Microsoft Edge installation skipped"
    fi
}

function install_jetbrains_toolbox() {
    log "INFO" "Starting Jetbrains Toolbox installation"

    if prompt_user "yes_no" "Would you like to install Jetbrains Toolbox?"; then
        (
            local JBT_VERSION
            JBT_VERSION=$(curl --silent 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' 2>/dev/null | jq '.TBA[0].build' -r 2>/dev/null)
            curl -sL "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JBT_VERSION}.tar.gz" 2>/dev/null | tar -zx --strip-components=1 -C ~/bin > /dev/null 2>&1
            printf 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/jetbrains.conf > /dev/null
            sudo sysctl -p --system > /dev/null 2>&1
        ) & show_progress $! "Installing Jetbrains Toolbox"
        log "INFO" "Jetbrains Toolbox installed successfully"
    else
        log "INFO" "Jetbrains Toolbox installation skipped"
    fi
}

function install_docker_and_docker_compose() {
    log "INFO" "Starting Docker and Docker Compose installation"

    if prompt_user "yes_no" "Would you like to install Docker and Docker Compose?"; then
        (
            for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
                sudo apt remove -y $pkg > /dev/null 2>&1 || true
            done

            # Add Docker's official GPG key:
            sudo apt update > /dev/null 2>&1
            sudo apt -y install ca-certificates curl > /dev/null 2>&1
            sudo install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 2>/dev/null
            sudo chmod a+r /etc/apt/keyrings/docker.asc > /dev/null 2>&1

            # Add the repository to Apt sources:
            echo \
              "deb [arch=$(dpkg --print-architecture 2>/dev/null) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt update > /dev/null 2>&1
            sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
            sudo usermod -a -G docker "${USER}" > /dev/null 2>&1
        ) & show_progress $! "Installing Docker and Docker Compose"
        log "INFO" "Docker and Docker Compose installed successfully"
        log "INFO" "Please log out and back in for Docker group changes to take effect"
    else
        log "INFO" "Docker and Docker Compose installation skipped"
    fi
}

function install_podman_cli_and_desktop() {
    log "INFO" "Starting Podman installation"

    if prompt_user "yes_no" "Would you like to install Podman CLI?"; then
        (
            sudo apt -y install podman > /dev/null 2>&1
        ) & show_progress $! "Installing Podman CLI"
        log "INFO" "Podman CLI installed successfully"
    else
        log "INFO" "Podman CLI installation skipped"
    fi

    if prompt_user "yes_no" "Would you like to install Podman Desktop (using Flatpak)?"; then
        (
            sudo apt -y install flatpak > /dev/null 2>&1
            flatpak install -y --noninteractive flathub io.podman_desktop.PodmanDesktop > /dev/null 2>&1
        ) & show_progress $! "Installing Podman Desktop"
        log "INFO" "Podman Desktop installed successfully"
    else
        log "INFO" "Podman Desktop installation skipped"
    fi
}

function install_ctop() {
    log "INFO" "Starting ctop installation"

    local message="Would you like to install ctop?\nRead https://ctop.sh/ for details."

    if prompt_user "yes_no" "$message"; then
        (
            local CTOP_VERSION
            CTOP_VERSION=$(curl --silent 'https://api.github.com/repos/bcicen/ctop/releases/latest' 2>/dev/null | jq '.tag_name' -r 2>/dev/null)
            sudo curl -sL "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION:1}-linux-amd64" -o /usr/local/bin/ctop 2>/dev/null
            sudo chmod +x /usr/local/bin/ctop > /dev/null 2>&1
        ) & show_progress $! "Installing ctop"
        log "INFO" "ctop installed successfully"
    else
        log "INFO" "ctop installation skipped"
    fi
}

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

function install_phpstorm_url_handler() {
    log "INFO" "Starting PhpStorm URL handler installation"

    if prompt_user "yes_no" "Would you like to install PhpStorm URL handler?"; then
        (
            sudo apt -y install desktop-file-utils > /dev/null 2>&1
            cp bin/phpstorm-url-handler ~/bin > /dev/null 2>&1
            chmod +x ~/bin/phpstorm-url-handler > /dev/null 2>&1
            sudo desktop-file-install --rebuild-mime-info-cache bin/phpstorm-url-handler.desktop > /dev/null 2>&1
        ) & show_progress $! "Installing PhpStorm URL handler"
        log "INFO" "PhpStorm URL handler installed successfully"
    else
        log "INFO" "PhpStorm URL handler installation skipped"
    fi
}

function install_aws_cli() {
    log "INFO" "Starting AWS CLI v2 installation"

    if prompt_user "yes_no" "Would you like to install AWS CLI v2?"; then
        (
            curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 2>/dev/null
            unzip -q awscliv2.zip > /dev/null 2>&1
            sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update > /dev/null 2>&1
            rm -rf ./aws awscliv2.zip > /dev/null 2>&1
        ) & show_progress $! "Installing AWS CLI v2"
        log "INFO" "AWS CLI v2 installed successfully"
    else
        log "INFO" "AWS CLI v2 installation skipped"
    fi
}

function install_k8s_lens_desktop() {
    log "INFO" "Starting K8s Lens Desktop installation"

    if prompt_user "yes_no" "Would you like to install K8s Lens Desktop?"; then
        (
            wget https://api.k8slens.dev/binaries/latest.x86_64.AppImage -q -O ~/bin/lens-desktop.AppImage 2>/dev/null
            chmod +x ~/bin/lens-desktop.AppImage > /dev/null 2>&1
            cp .local/share/applications/Lens.desktop ~/.local/share/applications/Lens.desktop > /dev/null 2>&1
            update-desktop-database ~/.local/share/applications > /dev/null 2>&1
            xdg-mime default Lens.desktop x-scheme-handler/lens > /dev/null 2>&1
            xdg-settings set default-url-scheme-handler lens Lens.desktop > /dev/null 2>&1
        ) & show_progress $! "Installing K8s Lens Desktop"
        log "INFO" "K8s Lens Desktop installed successfully (executable: lens-desktop)"
    else
        log "INFO" "K8s Lens Desktop installation skipped"
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

function install_brave() {
    log "INFO" "Starting Brave browser installation"

    if prompt_user "yes_no" "Would you like to install Brave browser?"; then
        (
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 2>/dev/null
            printf "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
            sudo apt -y update > /dev/null 2>&1 && sudo apt -y install brave-browser > /dev/null 2>&1
        ) & show_progress $! "Installing Brave browser"
        log "INFO" "Brave browser installed successfully"
    else
        log "INFO" "Brave browser installation skipped"
    fi
}

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

function install_vscode() {
    log "INFO" "Starting VS Code installation"

    if prompt_user "yes_no" "Would you like to install Visual Studio Code?"; then
        (
            sudo apt -y install wget gpg > /dev/null 2>&1
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null | gpg --dearmor > packages.microsoft.gpg 2>/dev/null
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg > /dev/null 2>&1
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' 2>/dev/null
            rm -f packages.microsoft.gpg > /dev/null 2>&1
            sudo apt update > /dev/null 2>&1 && sudo apt install -y code > /dev/null 2>&1
        ) & show_progress $! "Installing VS Code"
        log "INFO" "VS Code installed successfully"
    else
        log "INFO" "VS Code installation skipped"
    fi
}

function install_cloud_tools() {
    log "INFO" "Starting cloud tools installation"

    if prompt_user "yes_no" "Would you like to install cloud tools (kubectl, helm, k9s)?"; then
        (
            # Install kubectl
            local kubectl_version
            kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
            curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl" 2>/dev/null
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl > /dev/null 2>&1
            rm kubectl > /dev/null 2>&1

            # Install helm
            curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 2>/dev/null | bash > /dev/null 2>&1

            # Install k9s
            curl -sS https://webinstall.dev/k9s 2>/dev/null | bash > /dev/null 2>&1
        ) & show_progress $! "Installing cloud tools"
        log "INFO" "Cloud tools installed successfully"
    else
        log "INFO" "Cloud tools installation skipped"
    fi
}

function install_dnscrypt_proxy() {
    log "INFO" "Starting DNSCrypt-proxy installation"

    if prompt_user "yes_no" "Would you like to install DNSCrypt-proxy?"; then
        (
            # Create installation directory
            local install_dir="${HOME}/bin/dnscrypt-proxy"
            mkdir -p "${install_dir}" > /dev/null 2>&1

            # Get latest version and download
            local version
            version=$(curl --silent 'https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest' 2>/dev/null | jq '.tag_name' -r 2>/dev/null)

            log "INFO" "Installing DNSCrypt-proxy version ${version}"
            curl -sL "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${version}/dnscrypt-proxy-linux_x86_64-${version}.tar.gz" 2>/dev/null | \
                tar -zx --strip-components=1 -C "${install_dir}" > /dev/null 2>&1

            # Configure DNSCrypt
            cp "${install_dir}/example-dnscrypt-proxy.toml" "${install_dir}/dnscrypt-proxy.toml" > /dev/null 2>&1

            # Update configuration
            sed -i 's/# server_names = \[.+\]/server_names = \["cloudflare", "cloudflare-ipv6"\]/' "${install_dir}/dnscrypt-proxy.toml" > /dev/null 2>&1
            sed -i 's/listen_addresses = \[.+\]/listen_addresses = \["127.0.0.1:53", "[::1]:53"\]/' "${install_dir}/dnscrypt-proxy.toml" > /dev/null 2>&1

            # Configure NetworkManager
            printf "[main]\ndns=none\n" | sudo tee /etc/NetworkManager/conf.d/99-dnscrypt.conf > /dev/null

            # Create systemd service
            sudo tee /etc/systemd/system/dnscrypt-proxy.service > /dev/null << EOF
[Unit]
Description=DNSCrypt-proxy client
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy/wiki
After=network.target
Before=nss-lookup.target
Wants=network.target nss-lookup.target

[Service]
Type=simple
NonBlocking=true
ExecStart=${install_dir}/dnscrypt-proxy -config ${install_dir}/dnscrypt-proxy.toml
Restart=always
RestartSec=2
User=${USER}

[Install]
WantedBy=multi-user.target
EOF

            # Disable and stop systemd-resolved
            if systemctl is-active systemd-resolved >/dev/null 2>&1; then
                sudo systemctl stop systemd-resolved > /dev/null 2>&1
                sudo systemctl disable systemd-resolved > /dev/null 2>&1
            fi

            # Remove resolvconf if installed
            if dpkg -l | grep -q resolvconf 2>/dev/null; then
                sudo apt -y remove resolvconf > /dev/null 2>&1
            fi

            # Backup and configure resolv.conf
            if [[ -L /etc/resolv.conf ]]; then
                sudo rm /etc/resolv.conf > /dev/null 2>&1
            else
                sudo cp /etc/resolv.conf /etc/resolv.conf.backup > /dev/null 2>&1
            fi

            printf "nameserver 127.0.0.1\noptions edns0\n" | sudo tee /etc/resolv.conf > /dev/null

            # Start DNSCrypt service
            sudo systemctl daemon-reload > /dev/null 2>&1
            sudo systemctl enable dnscrypt-proxy > /dev/null 2>&1
            sudo systemctl start dnscrypt-proxy > /dev/null 2>&1

            # Restart NetworkManager
            sudo systemctl restart NetworkManager > /dev/null 2>&1

        ) & show_progress $! "Installing and configuring DNSCrypt-proxy"

        log "INFO" "DNSCrypt-proxy installation completed"
        printf "\n System changes made:\n"
        printf "   - DNSCrypt-proxy installed to %s\n" "${HOME}/bin/dnscrypt-proxy"
        printf "   - systemd-resolved disabled\n"
        printf "   - DNSCrypt-proxy service created and enabled\n"
        printf "   - DNS configuration updated to use DNSCrypt-proxy\n"

        if prompt_user "yes_no" "Would you like to test DNS resolution?"; then
            dig +short google.com 2>/dev/null
            printf "\nDNS servers in use:\n"
            resolvectl status 2>/dev/null
        fi
    else
        log "INFO" "DNSCrypt-proxy installation skipped"
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

#
# Terminal Customization Functions
#

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

#
# Installation Menu System
#

# Function to show a checkbox menu with whiptail
function show_whiptail_menu() {
    local title=$1
    local -n options_ref=$2
    local -n funcs_ref=$3
    local -n recommended_ref=$4
    
    # Prepare options array for whiptail
    local num_options=${#options_ref[@]}
    local whiptail_options=()
    
    # Add special options
    whiptail_options+=("ALL" "Select All Options" "OFF")
    whiptail_options+=("RECOMMENDED" "Select Recommended Options" "OFF")
    whiptail_options+=("NONE" "Deselect All Options" "OFF")
    
    # Add regular options
    for ((i=0; i<num_options; i++)); do
        whiptail_options+=("$i" "${options_ref[$i]}" "OFF")
    done
    
    # Calculate height and width
    local height=$((num_options + 15))
    local width=78
    
    # Show checkbox dialog
    local selected=$(whiptail --title "$title" \
                      --checklist "Select options to install (SPACE to toggle, ENTER to confirm):" \
                      $height $width $((num_options + 5)) \
                      "${whiptail_options[@]}" \
                      3>&1 1>&2 2>&3)
    
    # Exit if cancelled
    if [ $? -ne 0 ]; then
        echo "Cancelled"
        return 1
    fi
    
    # Handle special selections
    if [[ $selected == *"ALL"* ]]; then
        # Return all function names
        for ((i=0; i<num_options; i++)); do
            echo "${funcs_ref[$i]}"
        done
        return 0
    elif [[ $selected == *"RECOMMENDED"* ]]; then
        # Return recommended function names
        for ((i=0; i<num_options; i++)); do
            if [[ ${recommended_ref[$i]} -eq 1 ]]; then
                echo "${funcs_ref[$i]}"
            fi
        done
        return 0
    elif [[ $selected == *"NONE"* ]]; then
        # Return nothing
        return 0
    fi
    
    # Process regular selections
    for item in $(echo $selected | tr -d '"' | tr ' ' '\n'); do
        if [[ $item =~ ^[0-9]+$ ]]; then
            echo "${funcs_ref[$item]}"
        fi
    done
    
    return 0
}

# Function to show a checkbox menu with pure bash
function show_bash_menu() {
    local title=$1
    local -n options_ref=$2
    local -n funcs_ref=$3
    local -n recommended_ref=$4
    
    local num_options=${#options_ref[@]}
    local selected=()
    
    # Initialize all as unselected
    for ((i=0; i<num_options; i++)); do
        selected[$i]=0
    done
    
    while true; do
        clear
        echo "================================================================================"
        echo "                            $title"
        echo "================================================================================"
        echo ""
        echo "Select options to install (enter numbers to toggle, then press ENTER when done):"
        echo ""
        
        # Special options
        echo "Special options:"
        echo "  A) [ ] Select All"
        echo "  R) [ ] Select Recommended"
        echo "  N) [ ] Deselect All"
        echo ""
        
        # Regular options
        echo "Installation options:"
        for ((i=0; i<num_options; i++)); do
            local checkbox="[ ]"
            local recommend=""
            
            if [[ ${selected[$i]} -eq 1 ]]; then
                checkbox="[x]"
            fi
            
            if [[ ${recommended_ref[$i]} -eq 1 ]]; then
                recommend=" (recommended)"
            fi
            
            printf "  %2d) %s %s%s\n" $((i+1)) "$checkbox" "${options_ref[$i]}" "$recommend"
        done
        
        echo ""
        echo "Enter your selection (numbers, A, R, N, or 'done' to proceed): "
        read -r selection
        
        # Handle special inputs
        if [[ "${selection,,}" == "a" ]]; then
            # Select all
            for ((i=0; i<num_options; i++)); do
                selected[$i]=1
            done
        elif [[ "${selection,,}" == "r" ]]; then
            # Select recommended
            for ((i=0; i<num_options; i++)); do
                if [[ ${recommended_ref[$i]} -eq 1 ]]; then
                    selected[$i]=1
                else
                    selected[$i]=0
                fi
            done
        elif [[ "${selection,,}" == "n" ]]; then
            # Deselect all
            for ((i=0; i<num_options; i++)); do
                selected[$i]=0
            done
        elif [[ "${selection,,}" == "done" || -z "$selection" ]]; then
            # Confirm selection
            break
        else
            # Toggle individual selections
            IFS=',' read -ra indices <<< "$selection"
            for index in "${indices[@]}"; do
                if [[ "$index" =~ ^[0-9]+$ ]]; then
                    idx=$((index-1))
                    if [[ $idx -ge 0 && $idx -lt num_options ]]; then
                        selected[$idx]=$((1-selected[$idx]))  # Toggle
                    fi
                fi
            done
        fi
    done
    
    # Return selected function names
    for ((i=0; i<num_options; i++)); do
        if [[ ${selected[$i]} -eq 1 ]]; then
            echo "${funcs_ref[$i]}"
        fi
    done
    
    return 0
}

# Main installation menu function with fallback
function show_installation_menu() {
    local title=$1
    local -n options_ref=$2
    local -n funcs_ref=$3
    local -n recommended_ref=$4
    
    # Check if whiptail is available
    if command -v whiptail >/dev/null 2>&1; then
        # Use whiptail
        show_whiptail_menu "$title" options_ref funcs_ref recommended_ref
        return $?
    else
        # Offer to install whiptail
        echo "The 'whiptail' package is not installed. It provides a better interface for selections."
        echo "Would you like to install it now? (y/n)"
        read -r install_whiptail
        
        if [[ "${install_whiptail,,}" == "y"* ]]; then
            log "INFO" "Installing whiptail for improved UI"
            (
                sudo apt-get update -qq >/dev/null 2>&1
                sudo apt-get install -y libnewt0.52 >/dev/null 2>&1
            ) & show_progress $! "Installing whiptail"
            
            # Now try whiptail again
            if command -v whiptail >/dev/null 2>&1; then
                show_whiptail_menu "$title" options_ref funcs_ref recommended_ref
                return $?
            else
                log "WARN" "Failed to install whiptail, using fallback UI"
            fi
        fi
        
        # Fallback to bash UI
        show_bash_menu "$title" options_ref funcs_ref recommended_ref
        return $?
    fi
}
