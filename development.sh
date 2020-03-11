#!/usr/bin/env bash

set -eux

# Install Jetbrains Toolbox
JBT_VERSION=$(curl --silent 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | jq '.TBA[0].build' -r)
curl -L "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JBT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ~/bin

# For Jetbrains Idea
echo 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/jetbrains.conf
sudo sysctl -p --system

# Install Docker and Docker Compose
sudo apt -y install docker.io docker-compose
sudo usermod -a -G docker ${USER}

# Install CTop to view running containers
CTOP_VERSION=$(curl --silent 'https://api.github.com/repos/bcicen/ctop/releases/latest' | jq '.name' -r)
sudo curl -L "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64" -o /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop

# Install NVM and Node.js
NVM_VERSION=$(curl --silent 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq '.name' -r)
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# Install Insomnia API testing tool
sudo snap install insomnia


# install symfony cli
# curl -sS https://get.symfony.com/cli/installer | bash
# sudo mv /home/ygarris/.symfony/bin/symfony /usr/local/bin/symfony

# Install Phpstorm url handler
# sudo apt -y install desktop-file-utils
# cp bin/phpstorm-url-handler ~/bin
# sudo desktop-file-install --rebuild-mime-info-cache bin/phpstorm-url-handler.desktop

# install composer
# EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
# php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
# ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
# if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
# then
#     >&2 echo 'ERROR: Invalid installer signature'
#     rm composer-setup.php
#     exit 1
# fi
# sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
# RESULT=$?
# rm composer-setup.php
# exit $RESULT
