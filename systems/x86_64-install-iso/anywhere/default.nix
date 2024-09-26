# Install-ISO for https://github.com/nix-community/nixos-anywhere

#$ nix build .#install-isoConfigurations.anywhere
#$ cp result/iso/nixos-<version>.iso /dev/sdX

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [ ];

  schallernetz = { };

  environment.systemPackages = with pkgs; [
    fastfetch
  ];

  users.users.root.openssh.authorizedKeys.keys = config.users.users."admin".openssh.authorizedKeys.keys;

  systemd.network = {
    enable = true;
    networks."10-all" = {
      name = "*";
      address = [ "***REMOVED_IPv6***/64" ];
    };
  };

  # iso-configuration
  isoImage.squashfsCompression = "zstd -Xcompression-level 5";
  boot.kernelParams = [ "copytoram" ];
  boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "vfat" "xfs" "ntfs" "cifs" ]; # remove ZFS support

  system.stateVersion = "24.05";
}
