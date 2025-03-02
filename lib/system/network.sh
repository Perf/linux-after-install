#!/usr/bin/env bash

# Network configuration module
# Contains functions for configuring network settings

# Source common utilities
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/utils.sh"
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/core/ui.sh"

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