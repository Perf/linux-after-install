#!/usr/bin/env bash

# set generic hostname
HOSTNAME="linux-desktop-home"
if [[ $HOSTNAME != $(hostname) ]]; then
    echo "\nSetting new hostname: ${HOSTNAME}\n"
    sudo hostnamectl set-hostname ${HOSTNAME}
    sudo sed -i "s/127\.0\.1\.1\s.*/127\.0\.1\.1\t${HOSTNAME}/" /etc/hosts
fi

# Decrease swapiness
echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/swapiness.conf
sudo sysctl -p --system

# update packages
sudo apt -y update
sudo apt -y upgrade

# add Oibaf video drivers PPA
# https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers
sudo add-apt-repository -y ppa:oibaf/graphics-drivers

# add KDE repo and update
sudo add-apt-repository -y ppa:kubuntu-ppa/backports

# perform full update/upgrade
sudo apt -y update
sudo apt -y full-upgrade

# install packages
sudo apt -y install \
    software-properties-common \
    build-essential \
    steam \
    vlc \
    streamripper \
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
echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
sudo apt -y update && sudo apt -y install signal-desktop

# apt cleanup
sudo apt -y autoclean
sudo apt -y autoremove

# disable KDE Baloo indexer
balooctl disable
balooctl purge

# dns proxy
# https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Installation-linux
# CHECK apt install dnscrypt-proxy
mkdir -p ~/bin/dns-proxy
curl -L "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.36/dnscrypt-proxy-linux_x86_64-2.0.36.tar.gz" | tar -zxv --strip-components=1 -C ~/bin/dns-proxy
cp ~/bin/dns-proxy/example-dnscrypt-proxy.toml ~/bin/dns-proxy/dnscrypt-proxy.toml
## server_names = ['scaleway-fr', 'google', 'yandex', 'cloudflare']
# server_names = ['cloudflare', 'cloudflare-ipv6']
## listen_addresses = ['127.0.0.1:53']
# listen_addresses = ['127.0.0.1:53', '[::1]:53']
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo apt -y remove resolvconf
sudo cp /etc/resolv.conf /etc/resolv.conf.backup
sudo rm -f /etc/resolv.conf
echo "
nameserver 127.0.0.1
options edns0
" | sudo tee /etc/resolv.conf
