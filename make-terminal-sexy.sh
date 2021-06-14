#!/usr/bin/env bash

set -eu

# install shell apps
sudo apt -y install fontconfig mc vim git socat konsole yakuake powerline powerline-gitstatus

# install custom fonts and update font cache
mkdir -p ~/.local/share/fonts
cp -r .local/share/fonts/* ~/.local/share/fonts
fc-cache -f

# enable powerline for login shells
sudo ln -s /usr/share/powerline/integrations/powerline.sh /etc/profile.d/zz-powerline.sh

# set default monospace font
kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed "mononoki Nerd Font Mono,12,-1,5,50,0,0,0,0,0,Regular"

# copy all configs and settings
cp -r .config/* ~/.config
cp -r .local/* ~/.local
cp .vimrc ~/
