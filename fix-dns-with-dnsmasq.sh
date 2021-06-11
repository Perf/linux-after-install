#!/usr/bin/env bash

set -eu

sudo apt -y install dnsmasq

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo apt -y remove resolvconf

sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

NM_CONF="/etc/NetworkManager/NetworkManager.conf"

sudo cp "$NM_CONF" "$NM_CONF.orig"

if grep -q dns= "$NM_CONF"; then
    sudo sed -i 's/dns=.*/dns=default/' $NM_CONF
else
    sudo sed -i '/\[main\]/a dns=default' $NM_CONF
fi

sudo cp /etc/resolv.conf /etc/resolv.conf.backup
sudo rm -f /etc/resolv.conf
sudo touch /etc/resolv.conf

sudo systemctl restart NetworkManager
