#!/usr/bin/env bash

set -eu

source ./lib.sh

remove_snapd

set_hostname

set_swappiness

add_oibaf_repo

add_kubuntu_backports_repo

# perform full update/upgrade
sudo apt -y update
sudo apt -y full-upgrade

# install packages
sudo apt -y install \
    software-properties-common \
    build-essential \
    htop \
    jq \
    wget \
    curl \
    inxi \
    apt-transport-https \
    fwupd-signed

install_google_chrome

install_microsoft_edge

install_skype

install_signal

install_zoom

install_discord

# apt cleanup
sudo apt -y autoclean
sudo apt -y autoremove

# disable KDE Baloo indexer
balooctl disable
balooctl purge
