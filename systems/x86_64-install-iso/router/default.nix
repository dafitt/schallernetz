#$ nix build .#install-isoConfigurations.firewall
#$ cp result/iso/nixos-<version>.iso /dev/sdX

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [ ];

  schallernetz = {
    backups.localhost = false;
    backups.NAS4 = false;

    networking.router.enable = true;

    servers = {
      unbound.enable = true;
    };
  };

  # iso-configuration
  isoImage.squashfsCompression = "zstd -Xcompression-level 5";
  boot.kernelParams = [ "copytoram" ];
  boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "vfat" "xfs" "ntfs" "cifs" ]; # remove ZFS support

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
