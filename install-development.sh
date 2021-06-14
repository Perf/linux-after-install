#!/usr/bin/env bash

set -eu

mkdir -p ~/bin

# Install Jetbrains Toolbox
while true
do
    printf "Install Jetbrains Toolbox?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Jetbrains Toolbox [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Jetbrains Toolbox\n"
              JBT_VERSION=$(curl --silent 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | jq '.TBA[0].build' -r)
              curl -L "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JBT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ~/bin
              echo 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/jetbrains.conf
              sudo sysctl -p --system
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Install Docker and Docker Compose
while true
do
    printf "Install Docker and Docker Compose?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Docker and Docker Compose [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Docker and Docker Compose\n"
              sudo apt -y install docker.io docker-compose
              sudo usermod -a -G docker ${USER}
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Install CTop to view running containers
while true
do
    printf "Install ctop?\n"
    printf "Read https://github.com/bcicen/ctop for details.\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "ctop [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing ctop\n"
              CTOP_VERSION=$(curl --silent 'https://api.github.com/repos/bcicen/ctop/releases/latest' | jq '.name' -r)
              sudo curl -L "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64" -o /usr/local/bin/ctop
              sudo chmod +x /usr/local/bin/ctop
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Install Slack
while true
do
    printf "Install Slack?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Slack [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Slack\n"
              SLACK_VERSION=$(curl -silent "https://slack.com/intl/en-de/release-notes/linux" | grep -m 1 -o -E "<h2>Slack [0-9]+\.[0-9]+\.[0-9]+" | grep -m 1 -o -E "[0-9]+\.[0-9]+\.[0-9]+")
              wget "https://downloads.slack-edge.com/linux_releases/slack-desktop-${SLACK_VERSION}-amd64.deb" -O slack.deb
              sudo dpkg -i slack.deb || sudo apt -yf install
              rm slack.deb
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Install PhpStorm URL handler
while true
do
    printf "Install PhpStorm URL handler?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "PhpStorm URL handler [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing PhpStorm URL handler\n"
              sudo apt -y install desktop-file-utils
              cp bin/phpstorm-url-handler ~/bin
              chmod +x ~/bin/phpstorm-url-handler
              sudo desktop-file-install --rebuild-mime-info-cache bin/phpstorm-url-handler.desktop
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Install NVM and Node.js
#NVM_VERSION=$(curl --silent 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq '.name' -r)
#curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
#export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#nvm install --lts
