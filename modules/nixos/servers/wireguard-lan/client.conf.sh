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
  ipAddress="10.1.$((128 + (RANDOM % 127))).$((1 + (RANDOM % 254)))"
  ip6Address="***REMOVED_IPv6***::$(hexdump --length 2 --format '"%03x"' /dev/urandom | cut -c1-3)"
  privateKey="$(wg genkey)"
  publicKey="$(echo $privateKey | wg pubkey)"
  presharedKey="$(wg genpsk)"

  # File
  echo -e "$INFO File:\n$filepath"
  cat <<EOL >$filepath
[Interface]
Address = $ip6Address/80, $ipAddress/20
PrivateKey = $privateKey
DNS = ***REMOVED_IPv6***

[Peer]
PublicKey = ***REMOVED_WIREGUARD-KEY***
PresharedKey = $presharedKey
AllowedIPs = ***REMOVED_IPv6***::/60
Endpoint = lan.wireguard.***REMOVED_DOMAIN***:123
EOL

  # NixOS configuration
  nixosConfiguration=$(
    cat <<EOL
  {
    # $name
    publicKey = "$publicKey";
    presharedKey = "$presharedKey";
    allowedIPs = [ "$ip6Address/128" "$ipAddress/32" ];
  }
EOL
  )
  sed --in-place "\|\[| r /dev/stdin" $(dirname $0)/clients.nix <<<"$nixosConfiguration"

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
