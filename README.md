> !Github: This repository is just a representation of my server configuration, intended for viewing only. It will not work because secrets have been filtered out.

# Our Snowfall🌨️🍂 NixOS❄️ servers

-   [Our Snowfall🌨️🍂 NixOS❄️ servers](#our-snowfall️-nixos️-servers)
    -   [Servers](#servers)
    -   [Usage](#usage)
        -   [Upgrading](#upgrading)
        -   [Modules](#modules)
    -   [Structure](#structure)

## Overview

| Servers                                                   | Description                 | Software                                                   |
| --------------------------------------------------------- | --------------------------- | ---------------------------------------------------------- |
| adguardhome[🔗](https://adguardhome.lan.***REMOVED_DOMAIN***/) | DNS Blocker                 | [Adguard Home](https://github.com/AdguardTeam/AdGuardHome) |
| bitwarden[🔗](https://bitwarden.lan.***REMOVED_DOMAIN***/)     | Password Manager            | [Vaultwarden](https://github.com/dani-garcia/vaultwarden)  |
| DavidCAL[🔗](https://davidcal.lan.***REMOVED_DOMAIN***/.web/)  | Calendar & Address book     | [Radicale](https://github.com/Kozea/Radicale)              |
| DavidSYNC[🔗](https://davidsync.lan.***REMOVED_DOMAIN***/)     | File syncronization         | [Syncthing](https://github.com/syncthing/syncthing)        |
| forgejo[🔗](https://forgejo.lan.***REMOVED_DOMAIN***)          | Private GitHub              | [Forgejo](https://forgejo.org/)                            |
| haproxy-\*                                                | Reverse Proxy               | [HAProxy](https://github.com/haproxy/haproxy)              |
| MichiSHARE                                                | File share                  | [Samba](https://wiki.nixos.org/wiki/Samba)                 |
| ntfy[🔗](https://ntfy.lan.***REMOVED_DOMAIN***/)               | Push Notifications          | [ntfy.sh](https://github.com/binwiederhier/ntfy)           |
| searx[🔗](https://searx.***REMOVED_DOMAIN***/)                 | Recursive Web Search Engine | [SearXNG](https://github.com/searxng/searxng)              |
| unbound                                                   | Recursive & Authorative DNS | [Unbound](https://github.com/NLnetLabs/unbound)            |
| wireguard-\*                                              | VPN                         | [WireGuard](https://www.wireguard.com/)                    |

## Usage

### Upgrading

1. At a new NixOS release manually update inputs in [flake.nix](https://github.com/dafitt/schallernetz/blob/main/flake.nix). e.g. `24.05` -> `24.11`.

2. `nix flake update --commit-lock-file`

3. (optional) `nix flake check`, `nix build .#`

4. After that `rebuild test` first and then `switch` for every host.

### Modules

These modules are tested to be imported elsewhere:

```nix
inputs.schallernetz.url = "git+file:../schallernetz?shallow=1";

inputs.schallernetz.nixosModules."systemd/ntfy"
```

## Structure

The flakes structure is similar to my [dotfiles](https://github.com/dafitt/dotfiles?tab=readme-ov-file#structure), but without home-manager.
