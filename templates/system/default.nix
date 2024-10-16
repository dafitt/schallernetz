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
    backups.localhost = true;
    backups.NAS4 = true;
    backups.paths = [ ];

    servers.adguardhome.enable = false;
    servers.adguardhome.name = "adguardhome";
    servers.adguardhome.subnet = "server";
    servers.adguardhome.ip6HostAddress = ":8";
    servers.bitwarden.enable = false;
    servers.bitwarden.name = "bitwarden";
    servers.DavidCAL.enable = false;
    servers.DavidCAL.name = "DavidCAL";
    servers.DavidSYNC.enable = false;
    servers.DavidSYNC.name = "DavidSYNC";
    servers.DavidVPN.enable = false;
    servers.DavidVPN.name = "DavidVPN";
    servers.forgejo.enable = false;
    servers.forgejo.name = "forgejo";
    servers.haproxy-server.enable = false;
    servers.haproxy-server.name = "haproxy-server";
    servers.MichiSHARE.enable = false;
    servers.MichiSHARE.name = "MichiSHARE";
    servers.ntfy.enable = false;
    servers.ntfy.name = "ntfy";
    servers.searx.enable = false;
    servers.searx.name = "searx";
    servers.unbound.enable = false;
    servers.unbound.name = "unbound";

    environment.enable = true;

    locale.enable = true;

    networking.enable = true;

    nix.enable = true;

    ntfy-systemd.enable = true;
    ntfy-systemd.url = "https://ntfy.***REMOVED_DOMAIN***";

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

  # add device-specific nixos configuration here #

  system.stateVersion = "24.05";
}
