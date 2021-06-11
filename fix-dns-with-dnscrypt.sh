#!/usr/bin/env bash

set -eu

INSTALL_DNSCRYPT_DIR="~/bin/dnscrypt-proxy"
mkdir -p ${INSTALL_DNSCRYPT_DIR}
DNSCRYPT_VERSION=$(curl --silent 'https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest' | jq '.name' -r)
curl -L "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_VERSION}/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION}.tar.gz" | tar -zxv --strip-components=1 -C ${INSTALL_DNSCRYPT_DIR}
cp ${INSTALL_DNSCRYPT_DIR}/example-dnscrypt-proxy.toml ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
sed -i "s/# server_names = \['.+'\]/server_names = \['cloudflare', 'cloudflare-ipv6'\]/" ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
sed -i "s/listen_addresses = \['127\.0\.0\.1:53'\]/listen_addresses = \['127\.0\.0\.1:53', '\[::1\]:53'\]/" ${INSTALL_DNSCRYPT_DIR}/dnscrypt-proxy.toml
printf "
[main]
dns=none
" | sudo tee /etc/NetworkManager/conf.d/99-dnscrypt.conf
sudo systemctl restart NetworkManager
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo apt -y remove resolvconf
sudo cp /etc/resolv.conf /etc/resolv.conf.backup
sudo rm -f /etc/resolv.conf
printf "
nameserver 127.0.0.1
options edns0
" | sudo tee /etc/resolv.conf
