#!/usr/bin/env bash

IS_INSTALLED=$(ubuntu-drivers debug | grep -Po "installed: ([\d\w\.~-]+)")
if [[ "" == "$IS_INSTALLED" ]]; then
    sudo apt -y install software-properties-common
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt -y update
    sudo apt -y upgrade
    HAS_DRIVER=$(ubuntu-drivers devices | grep -o recommended)
    if [[ "" != "$HAS_DRIVER" ]]; then
        sudo ubuntu-drivers devices # if has recommended
        sudo ubuntu-drivers autoinstall
        sudo reboot
    fi
else
    echo "Driver ${IS_INSTALLED}"
fi
