# Check:
#$ nix flake check
#$ nixos-rebuild repl --fast --flake .#<host>

# Build:
#$ nixos-rebuild build --fast --flake .#<host>
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Activate:
#$ nixos-rebuild --flake .#<host> <test|switch|boot>
#$ nix run .#nixosConfigurations.<host>.config.system.build.toplevel

{ config, lib, pkgs, inputs, ... }:

let
  ip6HostAddress = ":fff";
in
with lib;
with lib.schallernetz; {
  imports = [
    ./hardware-configuration.nix

    ../../network-configuration.nix
  ];

  schallernetz = rec {
    # NOTE these are the defaults
    backups.localhost = false;
    backups.NAS4 = false;
    backups.magentacloudMICHI = false;
    backups.paths = [ ];
    backups.pauseServices = [ ];

    servers.adguardhome.enable = false;
    servers.adguardhome.name = "adguardhome";
    servers.adguardhome.subnet = "server";
    servers.adguardhome.ip6HostAddress = ":8";
    servers.bitwarden.enable = false;
    servers.bitwarden.name = "bitwarden";
    servers.bitwarden.subnet = "server";
    servers.bitwarden.ip6HostAddress = ":b51";
    servers.DavidCAL.enable = false;
    servers.DavidCAL.name = "DavidCAL";
    servers.DavidCAL.subnet = "server";
    servers.DavidCAL.ip6HostAddress = ":297";
    servers.DavidSYNC.enable = false;
    servers.DavidSYNC.name = "DavidSYNC";
    servers.DavidSYNC.subnet = "server";
    servers.DavidSYNC.ip6HostAddress = ":2b6";
    servers.forgejo.enable = false;
    servers.forgejo.name = "forgejo";
    servers.forgejo.subnet = "server";
    servers.forgejo.ip6HostAddress = ":7b9";
    servers.haproxy-server.enable = false;
    servers.haproxy-server.name = "haproxy-server";
    servers.haproxy-server.subnet = "server";
    servers.haproxy-server.ip6HostAddress = ":7fc";
    servers.haproxy-dmz.enable = false;
    servers.haproxy-dmz.name = "haproxy-dmz";
    servers.haproxy-dmz.subnet = "server";
    servers.haproxy-dmz.ip6HostAddress = ":7fd";
    servers.MichiSHARE.enable = false;
    servers.MichiSHARE.name = "MichiSHARE";
    servers.MichiSHARE.subnet = "server";
    servers.MichiSHARE.ip6HostAddress = ":c66";
    servers.ntfy.enable = false;
    servers.ntfy.name = "ntfy";
    servers.ntfy.subnet = "server";
    servers.ntfy.ip6HostAddress = ":e73";
    servers.searx.enable = false;
    servers.searx.name = "searx";
    servers.searx.subnet = "dmz";
    servers.searx.ip6HostAddress = ":89c";
    servers.torRelay.enable = false;
    servers.torRelay.name = "torRelay";
    servers.torRelay.subnet = "dmz";
    servers.torRelay.ip6HostAddress = ":58b";
    servers.unbound.enable = false;
    servers.unbound.name = "unbound";
    servers.unbound.subnet = "server";
    servers.unbound.ip6HostAddress = ":9";
    servers.uptimekuma.enable = false;
    servers.uptimekuma.name = "uptimekuma";
    servers.uptimekuma.subnet = "server";
    servers.uptimekuma.ip6HostAddress = ":711";
    servers.wireguard-lan.enable = false;
    servers.wireguard-lan.name = "wireguard-lan";
    servers.wireguard-lan.subnet = "lan";
    servers.wireguard-lan.ip6HostAddress = ":ef5";

    environment.enable = true;

    locale.enable = true;

    networking.enable = true;

    nix.enable = true;

    ntfy-systemd.enable = true;
    ntfy-systemd.url = "https://ntfy.lan.***REMOVED_DOMAIN***";

    ssh.enable = true;

    time.enable = true;

    users.admin.enable = true;
    users.rebuild.enable = true;
    users.root.enable = true;
    users.root.allowSshPasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
  ];

  systemd.network.networks = {
    "30-eth0" = {
      matchConfig.Name = "eth0";
      linkConfig.RequiredForOnline = "enslaved";
      vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };

    "60-server" = with config.schallernetz.networking.subnets.server; {
      # NOTE completion of bridge
      address = [
        "${uniqueLocal.prefix}:${ip6HostAddress}/64"
        "fe80:${ip6HostAddress}/64"
      ];
    };
    "60-management" = with config.schallernetz.networking.subnets.management; {
      # NOTE completion of bridge
      address = [
        "${uniqueLocal.prefix}:${ip6HostAddress}/64"
        "fe80:${ip6HostAddress}/64"
      ];
    };
  };

  # <<< add device-specific nixos configuration here

  system.stateVersion = "24.05";
}
