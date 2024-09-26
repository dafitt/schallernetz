# Installation
#$ nix run github:nix-community/nixos-anywhere -- --flake .#router root@<ip>
# Rebuild
#$ nixos-rebuild --fast --flake .#router --use-remote-sudo --target-host rebuild@router.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix

    disko.nixosModules.disko
    ./disk-configuration.nix
  ];

  schallernetz = {
    backups.localhost = false;
    backups.NAS4 = false;

    networking.router.enable = true;

    servers = {
      unbound.enable = true;
    };
  };

  # improve performance
  boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "vfat" "xfs" "ntfs" "cifs" ]; # remove ZFS support
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
