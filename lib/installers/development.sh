#!/usr/bin/env bash

# Development tools module
# Contains functions for installing development tools and environments

# Source common utilities
source "$(dirname "$(dirname "$0")")/core/utils.sh"
source "$(dirname "$(dirname "$0")")/core/ui.sh"
source "$(dirname "$0")/template.sh"

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

function install_kubectl() {
    log "INFO" "Starting kubectl installation"

    if prompt_user "yes_no" "Would you like to install kubectl? (Kubernetes command-line tool)"; then
        (
            # Install kubectl
            local kubectl_version
            kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
            curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl" 2>/dev/null
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl > /dev/null 2>&1
            rm kubectl > /dev/null 2>&1
        ) & show_progress $! "Installing kubectl"
        log "INFO" "kubectl installed successfully"
    else
        log "INFO" "kubectl installation skipped"
    fi
}

function install_helm() {
    log "INFO" "Starting Helm installation"

    if prompt_user "yes_no" "Would you like to install Helm? (Kubernetes package manager)"; then
        (
            # Install helm
            curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 2>/dev/null | bash > /dev/null 2>&1
        ) & show_progress $! "Installing Helm"
        log "INFO" "Helm installed successfully"
    else
        log "INFO" "Helm installation skipped"
    fi
}

function install_k9s() {
    log "INFO" "Starting K9s installation"

    if prompt_user "yes_no" "Would you like to install K9s? (Terminal UI to interact with Kubernetes)"; then
        (
            # Install k9s
            curl -sS https://webinstall.dev/k9s 2>/dev/null | bash > /dev/null 2>&1
        ) & show_progress $! "Installing K9s"
        log "INFO" "K9s installed successfully"
    else
        log "INFO" "K9s installation skipped"
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