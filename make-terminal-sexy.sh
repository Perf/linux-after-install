#!/usr/bin/env bash

set -eu

# install shell apps
sudo apt -y install fontconfig mc vim git socat konsole yakuake powerline > /dev/null 2>&1

# Create fonts directory if it doesn't exist
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Get the latest release version from GitHub API
echo "Fetching latest Nerd Fonts release version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "tag_name" | cut -d'"' -f4)
if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not determine latest version"
    exit 1
fi

# Download Mononoki font
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/Mononoki.zip"
echo "Downloading and installing Mononoki Nerd Font release ${LATEST_VERSION}..."
wget -q --show-progress "$FONT_URL"
unzip -q Mononoki.zip -d "$FONT_DIR/Mononoki"
cd
rm -rf "$TEMP_DIR"
fc-cache -f
if fc-list | grep -i "Mononoki" > /dev/null; then
    echo "✓ Mononoki Nerd Font was successfully installed!"
else
    echo "⚠ Warning: Font installation may have failed. Please check the output for errors."
fi

# enable powerline for login shells
#sudo ln -s /usr/share/powerline/integrations/powerline.sh /etc/profile.d/zz-powerline.sh

# set default monospace font
kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed "Mononoki Nerd Font,12,-1,5,50,0,0,0,0,0,Regular"

# copy all configs and settings
cp -r .config/* ~/.config
cp -r .local/* ~/.local
cp .vimrc ~/

# Install Starship
curl -sS https://starship.rs/install.sh | sh
# Add starship init to ~/.bashrc
echo 'eval "$(starship init bash)"' >> ~/.bashrc
starship preset gruvbox-rainbow -o ~/.config/starship.toml
