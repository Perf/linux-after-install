#!/usr/bin/env bash

set -eu

# Helper function for logging
function log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$message" >&2
}

# Helper function for showing progress
function show_progress() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r[%s] %s..." "${spin:$i:1}" "$message"
        sleep 0.1
    done
    printf "\r✓ %s...done\n" "$message"
}

# Helper function for user prompt
function prompt_user() {
    local prompt_type="${1}"    # yes_no, choice, or input
    local message="${2}"
    local default="${3:-}"
    local options="${4:-}"        # For choice type

    # Display formatted message with visual separator
    printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "🔹 %s\n" "$message"

    case "$prompt_type" in
        "yes_no")
            printf "[Y/n]: "
            read -r answer
            [[ -z "$answer" || "${answer,,}" == "y"* ]] && return 0 || return 1
            ;;
        "choice")
            IFS=',' read -ra choices <<< "$options"
            for i in "${!choices[@]}"; do
                printf "%d) %s\n" $((i+1)) "${choices[$i]}"
            done
            printf "Choose [1-%d]: " "${#choices[@]}"
            read -r selection
            printf "%s" "$selection"
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
    old_hostname=$(hostname)

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
            sudo hostnamectl set-hostname "$new_hostname" &&
            sudo sed -i "s/127\.0\.1\.1\s.*/127.0.1.1\t${new_hostname}/" /etc/hosts
        ) & show_progress $! "Updating hostname"

        if [[ "$(hostname)" == "$new_hostname" ]]; then
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
        sudo systemctl stop snapd.service snapd.socket snapd.seeded.service

        log "INFO" "Removing snap packages"
        for snap in $(snap list 2>/dev/null | awk 'NR>1 {print $1}'); do
            log "INFO" "Removing snap package: $snap"
            sudo snap remove --purge "$snap"
        done

        # Wait for snap processes
        while pgrep -a snap >/dev/null; do
            sleep 1
        done

        log "INFO" "Unmounting snap volumes"
        for mnt in $(mount | grep snapd | cut -d' ' -f3); do
            sudo umount -l "$mnt" || true
        done

        log "INFO" "Removing snapd package and configuration"
        sudo apt -y remove --purge snapd
        sudo apt -y autoremove --purge

        log "INFO" "Removing snap directories and cache"
        sudo rm -rf \
            /var/cache/snapd/ \
            /var/lib/snapd/ \
            /var/snap/ \
            /snap/ \
            ~/snap/

        log "INFO" "Removing remaining configuration"
        sudo rm -rf \
            /etc/snap/ \
            /usr/lib/snapd/ \
            /usr/share/snapd/ \
            /usr/share/keyrings/snapd.gpg

        log "INFO" "Configuring system to prevent snapd reinstallation"
        sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -1
EOF

        # Handle Firefox replacement if needed
        if ! command -v firefox >/dev/null && prompt_user "yes_no" "Would you like to re-install Firefox from Mozilla PPA?"; then
            log "INFO" "Installing Firefox from Mozilla PPA"
            sudo add-apt-repository -y ppa:mozillateam/ppa
            sudo tee /etc/apt/preferences.d/mozilla-firefox > /dev/null <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
            sudo apt update
            sudo apt install -y firefox
        fi

    ) & show_progress $! "Removing snapd and related components"

    log "INFO" "Snapd removal completed successfully"
    printf "\n💡 System changes made:\n"
    printf "   - All snap packages removed\n"
    printf "   - Snapd service and socket disabled\n"
    printf "   - Snapd package and configuration removed\n"
    printf "   - Snap directories cleaned up\n"
    printf "   - System configured to prevent snapd reinstallation\n"
    if command -v firefox >/dev/null; then
        printf "   - Firefox installed from Mozilla PPA\n"
    fi
}

function set_swappiness() {
    local new_swappiness=10
    local old_swappiness
    old_swappiness=$(cat /proc/sys/vm/swappiness)

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
            printf "vm.swappiness = %d" "$new_swappiness" | sudo tee /etc/sysctl.d/swapiness.conf
            sudo sysctl -p --system
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
            sudo add-apt-repository -y ppa:oibaf/graphics-drivers
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
            sudo add-apt-repository -y ppa:kubuntu-ppa/backports
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
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O _google_chrome.deb
            sudo dpkg -i _google_chrome.deb || sudo apt -yf install
            rm _google_chrome.deb
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
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
            sudo rm microsoft.gpg
            sudo apt -y update && sudo apt -y install microsoft-edge-stable
        ) & show_progress $! "Installing Microsoft Edge"
        log "INFO" "Microsoft Edge installed successfully"
    else
        log "INFO" "Microsoft Edge installation skipped"
    fi
}

# function install_skype() {
#     log "INFO" "Starting Skype installation"

#     if prompt_user "yes_no" "Would you like to install Skype?"; then
#         (
#             wget -q https://go.skype.com/skypeforlinux-64.deb
#             sudo dpkg -i skypeforlinux-64.deb || sudo apt -yf install
#             rm skypeforlinux-64.deb
#         ) & show_progress $! "Installing Skype"
#         log "INFO" "Skype installed successfully"
#     else
#         log "INFO" "Skype installation skipped"
#     fi
# }

# function install_signal() {
#     log "INFO" "Starting Signal installation"

#     if prompt_user "yes_no" "Would you like to install Signal?"; then
#         (
#             wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
#             cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
#             printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
#             sudo apt -y update && sudo apt -y install signal-desktop
#         ) & show_progress $! "Installing Signal"
#         log "INFO" "Signal installed successfully"
#     else
#         log "INFO" "Signal installation skipped"
#     fi
# }

function install_jetbrains_toolbox() {
    log "INFO" "Starting Jetbrains Toolbox installation"

    if prompt_user "yes_no" "Would you like to install Jetbrains Toolbox?"; then
        (
            local JBT_VERSION
            JBT_VERSION=$(curl --silent 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | jq '.TBA[0].build' -r)
            curl -L "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JBT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ~/bin
            printf 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/jetbrains.conf
            sudo sysctl -p --system
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
            for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt remove $pkg; done
            # Add Docker's official GPG key:
            sudo apt update
            sudo apt -y install ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository to Apt sources:
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo usermod -a -G docker "${USER}"
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
            sudo apt -y install podman
        ) & show_progress $! "Installing Podman CLI"
        log "INFO" "Podman CLI installed successfully"
    else
        log "INFO" "Podman CLI installation skipped"
    fi

    if prompt_user "yes_no" "Would you like to install Podman Desktop (using Flatpak)?"; then
        (
            sudo apt -y install flatpak
            flatpak install flathub io.podman_desktop.PodmanDesktop
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
            CTOP_VERSION=$(curl --silent 'https://api.github.com/repos/bcicen/ctop/releases/latest' | jq '.tag_name' -r)
            sudo curl -L "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION:1}-linux-amd64" -o /usr/local/bin/ctop
            sudo chmod +x /usr/local/bin/ctop
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
            SLACK_VERSION=$(curl -silent "https://slack.com/release-notes/linux" | grep -m 1 -o -E "<h2>Slack [0-9]+\.[0-9]+\.[0-9]+" | grep -m 1 -o -E "[0-9]+\.[0-9]+\.[0-9]+")
            wget -q "https://downloads.slack-edge.com/desktop-releases/linux/x64/${SLACK_VERSION}/slack-desktop-${SLACK_VERSION}-amd64.deb" -O _slack.deb
            sudo dpkg -i _slack.deb || sudo apt -yf install
            rm _slack.deb
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
            sudo apt -y install desktop-file-utils
            cp bin/phpstorm-url-handler ~/bin
            chmod +x ~/bin/phpstorm-url-handler
            sudo desktop-file-install --rebuild-mime-info-cache bin/phpstorm-url-handler.desktop
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
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
            rm -rf ./aws awscliv2.zip
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
            wget https://api.k8slens.dev/binaries/latest.x86_64.AppImage -q -O ~/bin/lens-desktop.AppImage
            chmod +x ~/bin/lens-desktop.AppImage
            cp .local/share/applications/Lens.desktop ~/.local/share/applications/Lens.desktop
            update-desktop-database ~/.local/share/applications
            xdg-mime default Lens.desktop x-scheme-handler/lens
            xdg-settings set default-url-scheme-handler lens Lens.desktop
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
            wget -q https://zoom.us/client/latest/zoom_amd64.deb
            sudo dpkg -i zoom_amd64.deb || sudo apt -yf install
            rm zoom_amd64.deb
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
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            printf "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
            sudo apt -y update && sudo apt -y install brave-browser
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
            wget https://download.live.ledger.com/latest/linux -q -O ~/bin/ledger-live-desktop.AppImage
            chmod +x ~/bin/ledger-live-desktop.AppImage
            cp .local/share/applications/LedgerLive.desktop ~/.local/share/applications/LedgerLive.desktop
            update-desktop-database ~/.local/share/applications
            xdg-mime default LedgerLive.desktop x-scheme-handler/ledgerlive
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
            wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash
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
            wget -q "https://discord.com/api/download?platform=linux&format=deb" -O _discord.deb
            sudo dpkg -i _discord.deb || sudo apt -yf install
            rm _discord.deb
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
            wget -q "https://download.cursor.sh/linux/appImage/x64/Cursor-latest.deb" -O _cursor.deb

            # Install the package
            sudo dpkg -i _cursor.deb || sudo apt -yf install

            # Cleanup
            rm _cursor.deb

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
            sudo apt -y install wget gpg
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg
            sudo apt update && sudo apt install -y code
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
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl

            # Install helm
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

            # Install k9s
            curl -sS https://webinstall.dev/k9s | bash
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
            mkdir -p "${install_dir}"

            # Get latest version and download
            local version
            version=$(curl --silent 'https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest' | jq '.tag_name' -r)

            log "INFO" "Installing DNSCrypt-proxy version ${version}"
            curl -L "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${version}/dnscrypt-proxy-linux_x86_64-${version}.tar.gz" | \
                tar -zxv --strip-components=1 -C "${install_dir}"

            # Configure DNSCrypt
            cp "${install_dir}/example-dnscrypt-proxy.toml" "${install_dir}/dnscrypt-proxy.toml"

            # Update configuration
            sed -i 's/# server_names = \[.+\]/server_names = \["cloudflare", "cloudflare-ipv6"\]/' "${install_dir}/dnscrypt-proxy.toml"
            sed -i 's/listen_addresses = \[.+\]/listen_addresses = \["127.0.0.1:53", "[::1]:53"\]/' "${install_dir}/dnscrypt-proxy.toml"

            # Configure NetworkManager
            printf "[main]\ndns=none\n" | sudo tee /etc/NetworkManager/conf.d/99-dnscrypt.conf

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
                sudo systemctl stop systemd-resolved
                sudo systemctl disable systemd-resolved
            fi

            # Remove resolvconf if installed
            if dpkg -l | grep -q resolvconf; then
                sudo apt -y remove resolvconf
            fi

            # Backup and configure resolv.conf
            if [[ -L /etc/resolv.conf ]]; then
                sudo rm /etc/resolv.conf
            else
                sudo cp /etc/resolv.conf /etc/resolv.conf.backup
            fi

            printf "nameserver 127.0.0.1\noptions edns0\n" | sudo tee /etc/resolv.conf

            # Start DNSCrypt service
            sudo systemctl daemon-reload
            sudo systemctl enable dnscrypt-proxy
            sudo systemctl start dnscrypt-proxy

            # Restart NetworkManager
            sudo systemctl restart NetworkManager

        ) & show_progress $! "Installing and configuring DNSCrypt-proxy"

        log "INFO" "DNSCrypt-proxy installation completed"
        printf "\n System changes made:\n"
        printf "   - DNSCrypt-proxy installed to %s\n" "${HOME}/bin/dnscrypt-proxy"
        printf "   - systemd-resolved disabled\n"
        printf "   - DNSCrypt-proxy service created and enabled\n"
        printf "   - DNS configuration updated to use DNSCrypt-proxy\n"

        if prompt_user "yes_no" "Would you like to test DNS resolution?"; then
            dig +short google.com
            printf "\nDNS servers in use:\n"
            resolvectl status
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
            sudo apt update
            sudo apt -y install ca-certificates wget
            sudo install -m 0755 -d /etc/apt/keyrings
            wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg
            sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc

            # Add the AnyDesk apt repository
            printf "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list

            # Update apt caches and install the AnyDesk client
            sudo apt update
            sudo apt -y install anydesk
        ) & show_progress $! "Installing AnyDesk"
        log "INFO" "AnyDesk installed successfully"
    else
        log "INFO" "AnyDesk installation skipped"
    fi
}
