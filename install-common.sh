#!/usr/bin/env bash

set -eu

# Get rid of snapd
while true
do
    printf "Remove snapd?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "remove snapd [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Removing snapd\n"
              apt -y purge snapd
              apt-mark hold snapd
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# set hostname
OLD_HOSTNAME=$(hostname)
while true
do
    printf "Set new hostname?\n"
    printf "<Enter> to keep current '%s' | type in new hostname\n" ${OLD_HOSTNAME}
    read -p "hostname [<Enter>|string]: " answer
    case ${answer} in
        '' )    printf "Keeping current hostname '%s'\n" ${OLD_HOSTNAME}
                break;;

        * )     printf "Setting new hostname '%s'\n" ${answer}
                sudo hostnamectl set-hostname ${answer}
                sudo sed -i "s/127\.0\.1\.1\s.*/127\.0\.1\.1\t${answer}/" /etc/hosts
                break;;
    esac
done

# set swappiness
NEW_SWAPPINESS=10
OLD_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
while true
do
    printf "Decrease swappiness?\n"
    printf "Enter new swappiness number | <Enter> to use recommended '%d' | 'c' to keep current '%d'\n" ${NEW_SWAPPINESS} ${OLD_SWAPPINESS}
    read -p "vm.swappiness [integer|<Enter>|c]: " answer
    case ${answer} in
        'c' )   printf "Keeping current swappiness '%d'\n" ${OLD_SWAPPINESS}
                NEW_SWAPPINESS="${OLD_SWAPPINESS}"
                break;;

        '' )    printf "Using recommended swappiness '%d'\n" ${NEW_SWAPPINESS}
                break;;

        * )     printf "Using provided swappiness '%d'\n" ${answer}
                NEW_SWAPPINESS="${answer}"
                break;;
    esac
done
if [[ "${NEW_SWAPPINESS}" != "${OLD_SWAPPINESS}" ]]; then
    printf "\nSetting new swappiness: '%d'\n" ${NEW_SWAPPINESS}
    printf "vm.swappiness = %d" ${NEW_SWAPPINESS} | sudo tee /etc/sysctl.d/swapiness.conf
    sudo sysctl -p --system
fi

# add Oibaf video drivers PPA
while true
do
    printf "Add Oibaf graphics drivers repository?\n"
    printf "Read https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers for details.\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Oibaf repo [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Adding Oibaf repository\n"
              sudo add-apt-repository -y ppa:oibaf/graphics-drivers
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# add Kubuntu backports PPA
while true
do
    printf "Add Kubuntu Backport repository (KDE Plasma, etc...).\n"
    printf "Read https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports for details.\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Kubuntu Backports repo [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Adding Kubuntu backports repository\n"
              sudo add-apt-repository -y ppa:kubuntu-ppa/backports
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

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
    inxi

# Google Chrome
while true
do
    printf "Install Google Chrome?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Google Chrome [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Google Chrome\n"
              wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
              sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt -yf install
              rm google-chrome-stable_current_amd64.deb
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

## Microsoft Edge
while true
do
    printf "Install Microsoft Edge (Beta)?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Microsoft Edge [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Microsoft Edge\n"
              curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
              sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
              sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-beta.list'
              sudo rm microsoft.gpg
              sudo apt -y update && sudo apt -y install microsoft-edge-beta
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Skype
while true
do
    printf "Install Skype?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Skype [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Skype\n"
              wget https://go.skype.com/skypeforlinux-64.deb
              sudo dpkg -i skypeforlinux-64.deb || sudo apt -yf install
              rm skypeforlinux-64.deb
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# Signal
while true
do
    printf "Install Signal?\n"
    printf "<Enter> for 'yes' | any other key for 'no'\n"
    read -p "Signal [<Enter>|any key]: " answer
    case ${answer} in
        '' )  printf "Installing Signal\n"
              wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
              cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
              printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
              sudo apt -y update && sudo apt -y install signal-desktop
              break;;

        * )   printf "Skipping\n"
              break;;
    esac
done

# apt cleanup
sudo apt -y autoclean
sudo apt -y autoremove

# disable KDE Baloo indexer
balooctl disable
balooctl purge
