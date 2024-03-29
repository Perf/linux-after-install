#!/usr/bin/env bash

set -eu

mkdir -p ~/bin

function remove_snapd() {
  while true
  do
      printf "\n\nRemove snapd?\n"
      printf "Troubleshoot: https://www.debugpoint.com/remove-snap-ubuntu/"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "remove snapd [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Removing snapd\n"
                # check if any snaps 1st
                #sudo snap remove --purge $(snap list | awk '/^([a-z0-9-])./ {printf "%s ", $1}')

                # check if mounted
                #sudo umount /var/snap

                # TODO: make proper snapd removal
                sudo unmount /var/snap/firefox/common/host-hunspell
                sudo snap remove --purge firefox
                sudo snap remove --purge snap-store
                sudo snap remove --purge gnome-3-38-2004
                sudo snap remove --purge gtk-common-themes
                sudo snap remove --purge snapd-desktop-integration
                sudo snap remove --purge bare
                sudo snap remove --purge core20
                sudo snap remove --purge snapd

                sudo apt -y remove --purge --autoremove snapd
                sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd
                sudo apt-mark hold snapd
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function set_hostname() {
  local OLD_HOSTNAME=$(hostname)
  while true
  do
      printf "\n\nSet new hostname?\n"
      printf "<Enter> to keep current '%s' | type in new hostname\n" ${OLD_HOSTNAME}
      read -p "hostname [<Enter>|string]: " answer
      case ${answer} in
          '' )    printf ">> Keeping current hostname '%s'\n" ${OLD_HOSTNAME}
                  break;;

          * )     printf ">> Setting new hostname '%s'\n" ${answer}
                  sudo hostnamectl set-hostname ${answer}
                  sudo sed -i "s/127\.0\.1\.1\s.*/127\.0\.1\.1\t${answer}/" /etc/hosts
                  break;;
      esac
  done
}

function set_swappiness() {
  local NEW_SWAPPINESS=10
  local OLD_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
  while true
  do
      printf "\n\nDecrease swappiness?\n"
      printf "Enter new swappiness number | <Enter> to use recommended '%d' | 'c' to keep current '%d'\n" ${NEW_SWAPPINESS} ${OLD_SWAPPINESS}
      read -p "vm.swappiness [integer|<Enter>|c]: " answer
      case ${answer} in
          'c' )   printf ">> Keeping current swappiness '%d'\n" ${OLD_SWAPPINESS}
                  NEW_SWAPPINESS="${OLD_SWAPPINESS}"
                  break;;

          '' )    printf ">> Setting recommended swappiness '%d'\n" ${NEW_SWAPPINESS}
                  break;;

          * )     printf ">> Setting provided swappiness '%d'\n" ${answer}
                  NEW_SWAPPINESS="${answer}"
                  break;;
      esac
  done
  if [[ "${NEW_SWAPPINESS}" != "${OLD_SWAPPINESS}" ]]; then
      printf "vm.swappiness = %d" ${NEW_SWAPPINESS} | sudo tee /etc/sysctl.d/swapiness.conf
      sudo sysctl -p --system
  fi
}

function add_oibaf_repo() {
  while true
  do
      printf "\n\nAdd Oibaf graphics drivers repository?\n"
      printf "Read https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers for details.\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Oibaf repo [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Adding Oibaf repository\n"
                sudo add-apt-repository -y ppa:oibaf/graphics-drivers
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function add_kubuntu_backports_repo() {
  while true
  do
      printf "\n\nAdd Kubuntu Backports repository (KDE Plasma, etc...).\n"
      printf "Read https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports for details.\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Kubuntu Backports repo [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Adding Kubuntu Backports repository\n"
                sudo add-apt-repository -y ppa:kubuntu-ppa/backports
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_google_chrome() {
  while true
  do
      printf "\n\nInstall Google Chrome?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Google Chrome [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Google Chrome\n"
                wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O _google_chrome.deb
                sudo dpkg -i _google_chrome.deb || sudo apt -yf install
                rm _google_chrome.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_microsoft_edge() {
  while true
  do
      printf "\n\nInstall Microsoft Edge?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Microsoft Edge [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Microsoft Edge\n"
                curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
                sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
                sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
                sudo rm microsoft.gpg
                sudo apt -y update && sudo apt -y install microsoft-edge-stable
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_skype() {
  while true
  do
      printf "\n\nInstall Skype?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Skype [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Skype\n"
                wget -q https://go.skype.com/skypeforlinux-64.deb
                sudo dpkg -i skypeforlinux-64.deb || sudo apt -yf install
                rm skypeforlinux-64.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_signal() {
  while true
  do
      printf "\n\nInstall Signal?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Signal [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Signal\n"
                wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
                cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
                printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
                sudo apt -y update && sudo apt -y install signal-desktop
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_jetbrains_toolbox() {
  while true
  do
      printf "\n\nInstall Jetbrains Toolbox?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Jetbrains Toolbox [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Jetbrains Toolbox\n"
                local JBT_VERSION=$(curl --silent 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | jq '.TBA[0].build' -r)
                curl -L "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JBT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ~/bin
                echo 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/jetbrains.conf
                sudo sysctl -p --system
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_docker_and_docker_compose() {
  while true
  do
      printf "\n\nInstall Docker and Docker Compose?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Docker and Docker Compose [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Docker and Docker Compose\n"
                sudo apt -y install ca-certificates curl gnupg lsb-release
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt update
                sudo apt -y install docker.io docker-compose-plugin docker-buildx-plugin
                sudo usermod -a -G docker ${USER}
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_ctop() {
  while true
  do
      printf "\n\nInstall ctop?\n"
      printf "Read https://github.com/bcicen/ctop for details.\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "ctop [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing ctop\n"
                local CTOP_VERSION=$(curl --silent 'https://api.github.com/repos/bcicen/ctop/releases/latest' | jq '.tag_name' -r)
                sudo curl -L "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION:1}-linux-amd64" -o /usr/local/bin/ctop
                sudo chmod +x /usr/local/bin/ctop
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_slack() {
  while true
  do
      printf "\n\nInstall Slack?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Slack [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Slack\n"
                local SLACK_VERSION=$(curl -silent "https://slack.com/release-notes/linux" | grep -m 1 -o -E "<h2>Slack [0-9]+\.[0-9]+\.[0-9]+" | grep -m 1 -o -E "[0-9]+\.[0-9]+\.[0-9]+")
                wget -q "https://downloads.slack-edge.com/releases/linux/${SLACK_VERSION}/prod/x64/slack-desktop-${SLACK_VERSION}-amd64.deb" -O _slack.deb
                sudo dpkg -i _slack.deb || sudo apt -yf install
                rm _slack.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_phpstorm_url_handler() {
  while true
  do
      printf "\n\nInstall PhpStorm URL handler?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "PhpStorm URL handler [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing PhpStorm URL handler\n"
                sudo apt -y install desktop-file-utils
                cp bin/phpstorm-url-handler ~/bin
                chmod +x ~/bin/phpstorm-url-handler
                sudo desktop-file-install --rebuild-mime-info-cache bin/phpstorm-url-handler.desktop
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_aws_cli() {
  while true
  do
      printf "\n\nInstall AWS CLI v2?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "aws cli [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing AWS CLI v2\n"
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install
                rm -rf ./aws awscliv2.zip
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_k8s_openlens() {
  while true
  do
      printf "\n\nInstall K8s Open Lens v.6.2.0?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "K8s Open Lens [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing K8s Open Lens\n"
                curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
                sudo apt update
                sudo apt install -y nodejs
                sudo npm install -g yarn
                git clone https://github.com/lensapp/lens.git /tmp/openlens
                cd /tmp/openlens
                git checkout v6.2.0
                make build
                sudo dpkg -i dist/OpenLens-6.2.0.amd64.deb
                rm -rf /tmp/openlens
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_zoom() {
  while true
  do
      printf "\n\nInstall Zoom?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Zoom [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Zoom\n"
                wget -q https://zoom.us/client/latest/zoom_amd64.deb
                sudo dpkg -i zoom_amd64.deb || sudo apt -yf install
                rm zoom_amd64.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_atom() {
  while true
  do
      printf "\n\nInstall Atom?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Atom [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Atom\n"
                wget -q https://atom.io/download/deb -O _atom.deb
                sudo dpkg -i _atom.deb || sudo apt -yf install
                rm _atom.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_brave() {
  while true
  do
      printf "\n\nInstall Brave browser?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Brave [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Brave\n"
                sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                printf "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
                sudo apt -y update && sudo apt -y install brave-browser
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_ledger_live() {
  while true
  do
      printf "\n\nInstall Ledger Live?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Ledger Live [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Ledger Live\n"
                wget https://download.live.ledger.com/latest/linux -q -O ~/bin/ledger-live-desktop.AppImage
                chmod +x ~/bin/ledger-live-desktop.AppImage
                cp .local/share/applications/ledgerlive.desktop ~/.local/share/applications/ledgerlive.desktop
                update-desktop-database ~/.local/share/applications
                xdg-mime default ledgerlive.desktop x-scheme-handler/ledgerlive
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_ledger_udev_rules() {
  while true
  do
      printf "\n\nInstall Ledger udev rules?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Ledger udev [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Ledger udev rules\n"
                wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}

function install_discord() {
  while true
  do
      printf "\n\nInstall Discord?\n"
      printf "<Enter> for 'yes' | any other key for 'no'\n"
      read -p "Discord [<Enter>|any key]: " answer
      case ${answer} in
          '' )  printf ">> Installing Discord\n"
                wget -q "https://discord.com/api/download?platform=linux&format=deb" -O _discord.deb
                sudo dpkg -i _discord.deb || sudo apt -yf install
                rm _discord.deb
                break;;

          * )   printf ">> Skipping\n"
                break;;
      esac
  done
}


# Install NVM and Node.js
#NVM_VERSION=$(curl --silent 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq '.name' -r)
#curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
#export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#nvm install --lts
