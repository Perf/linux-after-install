#!/usr/bin/env bash

set -eu

# set hostname
NEW_HOSTNAME="linux-desktop-home"
OLD_HOSTNAME="$(hostname)"
while true
do
    printf "Setting hostname."
    printf "Enter new hostname | hit <Enter> to use default '${NEW_HOSTNAME}' | enter 'c' to keep current '${OLD_HOSTNAME}'"
    read -p "hostname [string|<Enter>|c]: " answer
    case $answer in
        'c' )   printf "Keeping current hostname '${OLD_HOSTNAME}'."
                NEW_HOSTNAME="${OLD_HOSTNAME}"
                break;;

        '' )    printf "Using default hostname '${NEW_HOSTNAME}'."
                break;;

        * )     printf "Using provided hostname '${answer}'."
                NEW_HOSTNAME="${answer}"
                break;;
    esac
done
if [[ "${NEW_HOSTNAME}" != "${OLD_HOSTNAME}" ]]; then
    printf "\nSetting new hostname: ${NEW_HOSTNAME}\n"
    sudo hostnamectl set-hostname ${NEW_HOSTNAME}
    sudo sed -i "s/127\.0\.1\.1\s.*/127\.0\.1\.1\t${NEW_HOSTNAME}/" /etc/hosts
fi

# set swappiness
NEW_SWAPPINESS=10
OLD_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
while true
do
    printf "Decreasing swappiness."
    printf "Enter new swappiness number | hit <Enter> to use recommended '${NEW_SWAPPINESS}' | enter 'c' to keep current '${OLD_SWAPPINESS}'"
    read -p "vm.swappiness [integer|<Enter>|c]: " answer
    case $answer in
        'c' )   printf "Keeping current swappiness '${OLD_SWAPPINESS}'."
                NEW_SWAPPINESS="${OLD_SWAPPINESS}"
                break;;

        '' )    printf "Using recommended swappiness '${NEW_SWAPPINESS}'."
                break;;

        * )     printf "Using provided swappiness '${answer}'."
                NEW_SWAPPINESS="${answer}"
                break;;
    esac
done
if [[ "${NEW_SWAPPINESS}" != "${OLD_SWAPPINESS}" ]]; then
    echo "\nSetting new swappiness: ${NEW_SWAPPINESS}\n"
    printf "vm.swappiness = ${NEW_SWAPPINESS}" | sudo tee /etc/sysctl.d/swapiness.conf
    sudo sysctl -p --system
fi

# add Oibaf video drivers PPA
while true
do
    printf "Adding Oibaf graphics drivers repository."
    printf "Read https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers for details."
    printf "'y' to add | <Enter> to add | 'n' to skip adding"
    read -p "[y|<Enter>|n]: " answer
    case $answer in
        'n' )   printf "Skipping."
                break;;

        'y'|'' )    printf "Adding Oibaf repository."
                    sudo add-apt-repository -y ppa:oibaf/graphics-drivers
                    break;;
    esac
done

# add Kubuntu backports PPA
while true
do
    printf "Adding Kubuntu Backport repository (KDE Plasma, etc...)."
    printf "Read https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports for details."
    printf "'y' to add | <Enter> to add | 'n' to skip adding"
    read -p "[y|<Enter>|n]: " answer
    case $answer in
        'n' )   printf "Skipping."
                break;;

        'y'|'' )    printf "Adding Kubuntu backports repository."
                    sudo add-apt-repository -y ppa:kubuntu-ppa/backports
                    break;;
    esac
done

# perform full update/upgrade
sudo apt -y update
sudo apt -y full-upgrade

# install packages
sudo apt -y install \
    software-properties-common \
    build-essential \
    chromium-browser \
    firefox \
    htop \
    jq \
    telegram-desktop \
    wget \
    curl \
    inxi

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt -yf install
rm google-chrome*.deb

# Skype
wget https://go.skype.com/skypeforlinux-64.deb
sudo dpkg -i skypeforlinux-64.deb || sudo apt -yf install
rm skypeforlinux-64.deb

# Signal
curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
printf "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
sudo apt -y update && sudo apt -y install signal-desktop

# apt cleanup
sudo apt -y autoclean
sudo apt -y autoremove

# disable KDE Baloo indexer
balooctl disable
balooctl purge

# dns proxy
INSTALL_DNSCRYPT=0
while true
do
    printf "Installing dnscrypt-proxy."
    printf "Read https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Installation-linux for details."
    printf "'y' to add | <Enter> to add | 'n' to skip adding"
    read -p "[y|<Enter>|n]: " answer
    case $answer in
        'n' )   printf "Skipping."
                break;;

        'y'|'' )    printf "Installing dnscrypt-proxy."
                    INSTALL_DNSCRYPT=1
                    break;;
    esac
done
if [[ "${INSTALL_DNSCRYPT}" != "0" ]]; then
    INSTALL_DNSCRYPT_DIR="~/bin/dnscrypt-proxy"
    mkdir -p ${INSTALL_DNSCRYPT_DIR}
    DNSCRYPT_VERSION=$(curl --silent 'https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest' | jq '.name' -r)
    curl -L "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_VERSION}/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ${INSTALL_DNSCRYPT_DIR}
    cp ${INSTALL_DNSCRYPT_DIR}/example-dnscrypt-proxy.toml ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
    sed -i "s/# server_names = \['.+'\]/server_names = \['cloudflare', 'cloudflare-ipv6'\]/" ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
    sed -i "s/listen_addresses = \['127\.0\.0\.1:53'\]/listen_addresses = \['127\.0\.0\.1:53', '\[::1\]:53'\]/" ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
    printf "
[main]
dns=none
" | sudo tee /etc/NetworkManager/conf.d/99-dnscrypt.conf
    sudo systemctl restart NetworkManager
    sudo systemctl stop systemd-resolved
    sudo systemctl disable systemd-resolved
    sudo apt -y remove resolvconf
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo rm -f /etc/resolv.conf
    printf "
nameserver 127.0.0.1
options edns0
" | sudo tee /etc/resolv.conf
fi
