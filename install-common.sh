#!/usr/bin/env bash

# set generic hostname
HOSTNAME="linux-desktop-home"
if [[ $HOSTNAME != $(hostname) ]]; then
    echo "\nSetting new hostname: ${HOSTNAME}\n"
    sudo hostnamectl set-hostname ${HOSTNAME}
    sudo sed -i "s/127\.0\.1\.1\s.*/127\.0\.1\.1\t${HOSTNAME}/" /etc/hosts
fi

# update packages
sudo apt -y update
sudo apt -y upgrade

# add KDE repo and update
sudo add-apt-repository -y ppa:kubuntu-ppa/backports
sudo apt -y update
sudo apt -y full-upgrade

# install packages
sudo apt -y install \
    software-properties-common \
    build-essential \
    curl \
    steam \
    vlc \
    streamripper \
    chromium-browser \
    firefox \
    htop \
    jq \
    telegram-desktop \
    wget \
    curl
    
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
