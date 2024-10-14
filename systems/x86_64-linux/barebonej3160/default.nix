# Installation with install-iso anywhere
#$ nix run github:nix-community/nixos-anywhere -- --flake .#barebonej3160 root@***REMOVED_IPv6***%<enp?s0>
# Rebuild
#$ nixos-rebuild --flake .#barebonej3160 --use-remote-sudo --target-host rebuild@barebonej3160.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix
    ../../global-configuration.nix

    disko.nixosModules.disko
    ./disk-configuration.nix
  ];

  schallernetz = {
    networking.router.enable = true;

    servers = {
      unbound.enable = true;
      adguardhome.enable = true;
      wireguard-lan.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  systemd.network.networks = {
    "30-enp1s0" = {
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "wan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp2s0" = {
      matchConfig.Name = "enp2s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "lan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp3s0" = {
      matchConfig.Name = "enp3s0";
      linkConfig.RequiredForOnline = "enslaved";
      vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp4s0" = {
      matchConfig.Name = "enp4s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };
  };

  boot.loader.timeout = 0;
  boot.loader.grub.configurationLimit = 5;

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
