# linux-after-install

A comprehensive set of configuration scripts to streamline post-installation setup of **Kubuntu** and other Ubuntu-based distributions. These scripts automate common setup tasks, install essential software, and configure system settings for optimal performance.

## Core Features

- 🔧 System Configuration
- 📦 Package Management
- 🚀 Development Tools
- 🔒 Security & DNS Configuration
- 🖥️ Terminal Customization
- 💻 Application Installation

## Available Scripts

### install-common.sh
Basic system setup and common applications:
- System Configuration:
  - Remove snapd (optional)
  - Configure hostname
  - Optimize swap settings (configurable swappiness)
  - Add Oibaf graphics drivers repository (optional)
  - Add Kubuntu Backports repository (optional)
- Web Browsers:
  - Google Chrome
  - Microsoft Edge
- Communication Tools:
  - Skype
  - Signal
  - Zoom
  - Discord
- System Maintenance:
  - Full system upgrade
  - Disable KDE Baloo indexer

### install-development.sh
Development environment setup:
- IDEs and Text Editors:
  - Atom
  - JetBrains Toolbox
- Containerization:
  - Docker
  - Docker Compose
  - ctop (container monitoring)
- Cloud & DevOps:
  - AWS CLI v2
  - K8s Lens (Kubernetes IDE)
- Collaboration:
  - Slack
  - Microsoft Teams
- Additional Tools:
  - PhpStorm URL handler

### make-terminal-sexy.sh
Terminal enhancement suite:
- Essential Tools:
  - git
  - vim
  - mc (Midnight Commander)
  - yakuake (drop-down terminal)
  - powerline (status line)
- Font Installation:
  - mononoki Nerd Font
- Pre-configured settings for optimal terminal experience

### DNS Configuration Scripts

#### fix-dns.sh
Quick fix for Ubuntu's `systemd-resolved` DNS issues:
- Corrects resolv.conf symlink
- Basic DNS resolution fix

#### fix-dns-with-dnsmasq.sh
Alternative DNS solution using dnsmasq:
- Replaces systemd-resolved
- Lightweight and efficient DNS caching

#### fix-dns-with-dnscrypt.sh
Enhanced DNS security solution:
- Implements [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy)
- Provides encrypted DNS queries
- Enhanced privacy and security
- Note: May require additional configuration with VPNs

### Web3 Support (install-web3.0.sh)
Blockchain development and cryptocurrency tools:
- Brave Browser
- Ledger Live
- Ledger device udev rules

## Library Functions (lib.sh)
Core functionality used by other scripts:
- Interactive installation prompts
- System configuration utilities
- Package installation helpers
- Repository management
- Application-specific setup routines

## Usage

1. Clone the repository:
```bash
git clone https://github.com/Perf/linux-after-install.git
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Run desired scripts:
```bash
./install-common.sh
./install-development.sh
./make-terminal-sexy.sh
```

## Notes

- Scripts are primarily designed for Kubuntu but should work on most Ubuntu-based distributions
- Each installation step is interactive and can be skipped
- System configuration changes can be customized during installation
- All scripts include safety checks and error handling
- DNS configuration scripts are mutually exclusive - choose one approach

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is open-source and available for personal and commercial use.