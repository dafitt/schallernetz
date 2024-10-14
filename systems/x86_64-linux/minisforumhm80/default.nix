# Installation with install-iso anywhere
#$ nix run github:nix-community/nixos-anywhere -- --flake .#minisforumhm80 root@***REMOVED_IPv6***%<enp?s0>
# Rebuild
#$ nixos-rebuild --flake .#minisforumhm80 --use-remote-sudo --target-host rebuild@minisforumhm80.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

let
  ip6HostAddress = ":a80";
in
with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix
    ../../global-configuration.nix
  ];

  schallernetz = {
    backups = {
      localhost = true;
      NAS4 = true;
    };

    servers = {
      bitwarden.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      forgejo.enable = true;
      haproxy-dmz.enable = true;
      haproxy-server.enable = true;
      MichiSHARE.enable = true;
      ntfy.enable = true;
      searx.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

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
    "30-eno1" = {
      matchConfig.Name = "eno1";
      linkConfig.RequiredForOnline = "enslaved";
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

  users.users."admin".openssh.authorizedKeys.keys = [
    "***REMOVED_SSH-PUBLICKEY*** admin@barebonej3160"
  ];

  services.fstrim.enable = true; # SSD

  system.stateVersion = "23.11";
}
