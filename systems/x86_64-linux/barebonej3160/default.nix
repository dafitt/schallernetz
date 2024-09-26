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

    servers = {
      unbound.enable = true;
    };
  };

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
