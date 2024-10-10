#!/usr/bin/env nix
#!nix shell
#!nix nixpkgs#wireguard-tools
#!nix nixpkgs#hexdump
#!nix nixpkgs#qrencode
#!nix nixpkgs#perl
#!nix nixpkgs#bash --command bash

# Run this script to generate a new wireguard client: #$ env nix "./client.conf.sh"
# It creates the `client.conf` file, outputs the QR-Code and the corresponding NixOS configuration

INFO="[\e[1;34m INFO \e[0m]"     # [ INFO ]
ACTION="[\e[1;33m ACTION \e[0m]" # [ ACTION ]
HELP="[\e[1;36m HELP \e[0m]"     # [ HELP ]

echo -ne "$ACTION Hostname/FQDN/Identifier of the device [client]> " && read name && [ -z "$name" ] && name="client"
filepath="$(dirname $0)/$name.conf"

if [ ! -f "$filepath" ]; then
  ipAddress="10.0.$((RANDOM % 128)).$((RANDOM % 256))"
  ip6Address="fc00::$(hexdump -n 2 -e '"%03x"' </dev/urandom | cut -c1-3)"
  privateKey="$(wg genkey)"
  publicKey="$(echo $privateKey | wg pubkey)"
  presharedKey="$(wg genpsk)"

  # File
  echo -e "$INFO File:\n$filepath"
  cat <<EOL >$filepath
[Interface]
Address = $ip6Address/64, $ipAddress/8
ListenPort = 51820
PrivateKey = $privateKey
DNS = ***REMOVED_IPv6***

[Peer]
PublicKey = ***REMOVED_WIREGUARD-KEY***
PresharedKey = $presharedKey
AllowedIPs = ***REMOVED_IPv6***::/56
Endpoint = lan.wireguard.***REMOVED_DOMAIN***:123
EOL

  # NixOS configuration
  nixosConfiguration=$(
    cat <<EOL
                {
                  # $name
                  PublicKey = "$publicKey";
                  PresharedKey = "$presharedKey";
                  AllowedIPs = [ "$ip6Address/128" "$ipAddress/32" ];
                }
EOL
  )
  sed --in-place "\|wireguardPeers = \[| r /dev/stdin" $(dirname $0)/default.nix <<<"$nixosConfiguration"

  echo -e "$ACTION Commit the supplemented NixOS configuration:"
  read -p "wireguard.lan: added client $name"
fi

# QR-Code
echo -e "$INFO QR-Code:"
qrencode -t ansiutf8 -r $filepath

# HELP
echo -e $HELP
cat <<EOL
To import into Networkmanager run:
sudo nmcli connection import type wireguard file $name.conf
EOL
