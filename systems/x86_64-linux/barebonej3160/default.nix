# Installation
#$ nix run github:nix-community/nixos-anywhere -- --flake .#barebonej3160 root@***REMOVED_IPv6***%<enp?s0>
# Rebuild
#$ nixos-rebuild --fast --flake .#barebonej3160 --use-remote-sudo --target-host rebuild@barebonej3160.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix

    disko.nixosModules.disko
    ./disk-configuration.nix
  ];

  schallernetz = {
    networking.router.enable = true;

    servers = { };
  };

  # connect the physical interfaces to the right bridge and/or vlan
  systemd.network = {
    networks."10-enp1s0" = {
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "routable"; # make routing on this interface a dependency for network-online.target
      networkConfig = {
        Bridge = "wan"; # untagged
      };
    };
    networks."30-enp2s0" = {
      matchConfig.Name = "enp2s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "lan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    networks."30-enp3s0" = {
      matchConfig.Name = "enp3s0";
      linkConfig.RequiredForOnline = "enslaved";
      vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
      networkConfig = {
        Bridge = "lan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    networks."30-enp4s0" = {
      matchConfig.Name = "enp4s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };
  };

  boot.loader.timeout = 0;

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
