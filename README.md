# linux-after-install
A set of scripts that will make your life easier right after you installed a fresh copy of **Kubuntu**. However, with some modifications could be used on any Ubuntu-based distros.

`install-common.sh`
- Remove snapd
- Set new hostname
- Decrease swapiness
- Add [Oibaf graphics drivers](https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers) repository
- Add [Kubuntu Backports](https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports) repository
- Install Google Chrome
- Install Microsoft Edge (Beta)
- Install Skype
- Install Signal
- perform full system upgrade and disable KDE Baloo indexer

`install-development.sh`
- Install Jetbrains Toolbox
- Install Docker and Docker Compose
- Install [ctop](https://github.com/bcicen/ctop)
- Install Slack
- Install PhpStorm URL handler

`make-terminal-sexy.sh`
- Install git, vim, mc, yakuake, powerline, ...
- Install [mononoki Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Mononoki)
- Copy predefined configs

`fix-dns-with-dnsmasq.sh`

Ubuntu-based distros has a DNS resolution issue with `systemd-resolved`.
The solution is to replace it with `dnsmasq`. Fast and easy.

`fix-dns-with-dnscrypt.sh`

Other way to solve DNS issues on Ubuntu is to use [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy).
Increases your security level, however not tested it with VPNs.
