#$ nixos-rebuild --fast --flake .#minisforumhm80 --use-remote-sudo --target-host rebuild@minisforumhm80.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

let
  ip6Host = ":a80";
in
with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix

    ../../network-configuration.nix
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
      haproxy.enable = true;
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

  services.fstrim.enable = true; # SSD

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

    "60-server" = with config.schallernetz.networking.subnets.server; {
      # NOTE completion of bridge
      address = [
        "${uniqueLocal.prefix}:${ip6Host}/64"
        "fe80:${ip6Host}/64"
      ];
    };
    "60-management" = with config.schallernetz.networking.subnets.management; {
      # NOTE completion of bridge
      address = [
        "${uniqueLocal.prefix}:${ip6Host}/64"
        "fe80:${ip6Host}/64"
      ];
    };
  };

  system.stateVersion = "23.11";
}
