#!/usr/bin/env bash

set -eu

sudo echo ""

source ./lib.sh

remove_snapd

set_hostname

set_swappiness

add_oibaf_repo

add_kubuntu_backports_repo

# perform full update/upgrade
sudo apt -y update > /dev/null 2>&1
sudo apt -y full-upgrade > /dev/null 2>&1

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
    fwupd-signed > /dev/null 2>&1

install_google_chrome

install_microsoft_edge

install_zoom

install_discord

install_anydesk

install_transgui

# apt cleanup
sudo apt -y autoclean > /dev/null 2>&1
sudo apt -y autoremove > /dev/null 2>&1

# disable KDE Baloo indexer
balooctl disable > /dev/null 2>&1
balooctl purge > /dev/null 2>&1
