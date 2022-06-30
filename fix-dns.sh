#!/usr/bin/env bash

set -eu

sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo service systemd-resolved restart
