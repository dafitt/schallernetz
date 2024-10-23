> !Github: This repository is a representation of my server configuration, intended for viewing only. It will not work because secrets have been filtered out.

# Our Snowfall🌨️🍂 NixOS❄️ Network

-   [Our Snowfall🌨️🍂 NixOS❄️ Network](#our-snowfall️-nixos️-network)
    -   [Overview](#overview)
    -   [Configuration](#configuration)
        -   [Network](#network)
    -   [Usage](#usage)
        -   [Upgrading](#upgrading)
        -   [Importable modules](#importable-modules)
    -   [Structure](#structure)
        -   [Network](#network-1)
        -   [Servers](#servers)
    -   [👀, 🏆 and ❤️](#--and-️)

## Overview

| Servers                                                   | Description                   | Software                                                   |
| --------------------------------------------------------- | ----------------------------- | ---------------------------------------------------------- |
| adguardhome[🔗](https://adguardhome.lan.***REMOVED_DOMAIN***/) | DNS Blocker                   | [Adguard Home](https://github.com/AdguardTeam/AdGuardHome) |
| bitwarden[🔗](https://bitwarden.lan.***REMOVED_DOMAIN***/)     | Password Manager              | [Vaultwarden](https://github.com/dani-garcia/vaultwarden)  |
| DavidCAL[🔗](https://davidcal.lan.***REMOVED_DOMAIN***/.web/)  | Calendar & Address book       | [Radicale](https://github.com/Kozea/Radicale)              |
| DavidSYNC[🔗](https://davidsync.lan.***REMOVED_DOMAIN***/)     | File syncronization           | [Syncthing](https://github.com/syncthing/syncthing)        |
| forgejo[🔗](https://forgejo.lan.***REMOVED_DOMAIN***)          | Private GitHub                | [Forgejo](https://forgejo.org/)                            |
| haproxy-\*                                                | Reverse Proxy                 | [HAProxy](https://github.com/haproxy/haproxy)              |
| MichiSHARE                                                | File share                    | [Samba](https://wiki.nixos.org/wiki/Samba)                 |
| ntfy[🔗](https://ntfy.lan.***REMOVED_DOMAIN***/)               | Push Notifications            | [ntfy.sh](https://github.com/binwiederhier/ntfy)           |
| searx[🔗](https://searx.***REMOVED_DOMAIN***/)                 | Recursive Web Search Engine   | [SearXNG](https://github.com/searxng/searxng)              |
| unbound                                                   | Recursive & authoritative DNS | [Unbound](https://github.com/NLnetLabs/unbound)            |
| uptimekuma[🔗](https://uptimekuma.lan.***REMOVED_DOMAIN***/)   | Recursive Web Search Engine   | [Uptime Kuma](https://github.com/louislam/uptime-kuma)     |
| wireguard-\*                                              | VPN                           | [WireGuard](https://www.wireguard.com/)                    |

| Hosts          | Used for/as                                                 |
| -------------- | ----------------------------------------------------------- |
| barebonej3160  | Gateway, Subnetting, Routing, Firewall, DNS, VPN            |
| minisforumhm80 | Always-on host for lightweight servers and experimentation. |

## Configuration

### Network

Some words on networking, since networking is hard.

Read the [Networkstructure](#network-1) first.

We need to declare our network with the `schallernetz.networking`-option. See [modules/nixos/networking/default.nix](https://github.com/dafitt/schallernetz/blob/main/modules/nixos/networking/default.nix) for available options.

My network options like `schallernetz.networking.domain`, `schallernetz.networking.uniqueLocal` or `schallernetz.networking.subnets` must be set the same for every server host in this network. So I would recommend to put those options into a file like e.g. `systems/global-configuration.nix` and im port this file to every server host with `imports = [../../global-configuration.nix];`.

Physical interfaces: Since physical interfaces are always different, it makes no sense to declare them in a module or globally. So they must be declared in [systems/](https://github.com/dafitt/schallernetz/blob/main/systems/). An example:

```nix
systemd.network.networks = {
  "30-enp4s0" = {
    matchConfig.Name = "enp4s0";
    linkConfig.RequiredForOnline = "enslaved";
    vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
    networkConfig = {
      Bridge = "management"; # untagged
      LinkLocalAddressing = "no";
    };
  };
}
```

As you can see, you don't configure the network directly on the physical interface, you map the network to the interface via vlan or a bridge. If the server needs to be accessable through a network, we also need to give the associated bridge the desired static IPv6. Here the host can be accessed through the management network:

```nix
systemd.network.networks = {
  "60-management" = with config.schallernetz.networking.subnets.management; {
      # NOTE completion of bridge
    address = [
      "${uniqueLocal.prefix}***REMOVED_IPv6***/64"
      "***REMOVED_IPv6***/64"
    ];
  };
}
```

The router has of course slightly more bridge configuration than a normal host. See [systems/x86_64-linux/barebonej3160/default.nix](https://github.com/dafitt/schallernetz/blob/main/systems/x86_64-linux/barebonej3160/default.nix) for an example.

## Usage

### Upgrading

1. At a new NixOS release manually update inputs in [flake.nix](https://github.com/dafitt/schallernetz/blob/main/flake.nix). e.g. `24.05` -> `24.11`.

2. `nix flake update --commit-lock-file`

3. (optional) `nix flake check`, `nix build .#`

4. After that `rebuild test` first and then `switch` for every host.

### Importable modules

These modules are tested to be imported elsewhere:

```nix
inputs.schallernetz.nixosModules."ntfy-systemd"
```

These modules are designed to be imported elsewhere, not tested though:

```nix
inputs.schallernetz.nixosModules."networking"
inputs.schallernetz.nixosModules."networking/router"
```

## Structure

The flakes structure is similar to my [dotfiles](https://github.com/dafitt/dotfiles?tab=readme-ov-file#structure), but without home-manager.

### Network

I decided to build a IPv6 only network (for now) because

-   global IPv4 addresses are expensive to get nowadays
-   it was easier for me to setup (in comparison to NAT in IPv4)
-   it makes a clear subnet structure (one subnet always /64)
-   from some ISPs you don't get an IPv4 anymore.

I implemented the network with systemd-networkd, because ["`systemd.network` should be preferred over `networking.interfaces`"](https://wiki.nixos.org/wiki/Systemd/networkd)

I have a local nameserver within [modules/nixos/servers/unbound](https://github.com/dafitt/schallernetz/blob/main/modules/nixos/servers/unbound) which resolves all `lan.<myDomain>`. `<myDomain>` is beeing resolved trough my DNS provider. When internet is down, i can still access my services trough my local `lan.<myDomain>`.

### Servers

Every service is beeing executed in a seperate [NixOS Container](https://wiki.nixos.org/wiki/NixOS_Containers).

This has some advanages:

-   Every server has its own IP
-   Processes are sealed off from the host system (more security)
-   Can always be started and stopped

## 👀, 🏆 and ❤️

-   [tlaternet/tlaternet-server](https://gitea.tlater.net/tlaternet/tlaternet-server)
