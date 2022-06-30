# linux-after-install
A set of scripts that will make your life easier right after you installed a fresh copy of **Kubuntu**. However, with some modifications could be used on any Ubuntu-based distros.

`install-common.sh`
- Remove snapd
- Set new hostname
- Set new swapiness
- Add [Oibaf graphics drivers](https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers) repository
- Add [Kubuntu Backports](https://launchpad.net/~kubuntu-ppa/+archive/ubuntu/backports) repository
- Install Google Chrome
- Install Microsoft Edge (Beta)
- Install Skype
- Install Signal
- Install Zoom
- Install Discord
- perform full system upgrade and disable KDE Baloo indexer

`install-development.sh`
- Install Atom
- Install Jetbrains Toolbox
- Install Docker and Docker Compose
- Install [ctop](https://github.com/bcicen/ctop)
- Install Slack
- Install Microsoft Teams
- Install PhpStorm URL handler
- Install AWS CLI v2
- Install K8s Lens

`make-terminal-sexy.sh`
- Install git, vim, mc, yakuake, powerline, ...
- Install [mononoki Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Mononoki)
- Copy predefined configs

`fix-dns.sh`

Ubuntu-based distros has a DNS name resolution issue with `systemd-resolved`.
Most easy and common way to fix it is to change symlink or /etc/resolv.conf to point to correct file.

`fix-dns-with-dnsmasq.sh`

Other solution is to replace it with `dnsmasq`. Fast and easy.

`fix-dns-with-dnscrypt.sh`

Other way to solve DNS issues on Ubuntu is to use [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy).
Increases your security level, however not tested it with VPNs.
