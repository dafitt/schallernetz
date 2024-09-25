#$ nixos-rebuild --fast --flake .#minisforumhm80 --use-remote-sudo --target-host rebuild@minisforumhm80.lan.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  schallernetz = {
    servers = {
      adguardhome.enable = true;
      bitwarden.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      forgejo.enable = true;
      haproxy.enable = true;
      MichiSHARE.enable = true;
      ntfy.enable = true;
      searx.enable = true;
      unbound.enable = true;
      wireguard.enable = true;
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
    # connect physical port to bridge
    "30-enp4s0" = {
      matchConfig.Name = "enp4s0";
      networkConfig.Bridge = "br_lan";
      linkConfig.RequiredForOnline = "enslaved";
    };
    "40-br_lan" = {
      # NOTE completion of bridge
      address = [
        "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***/64"
      ];
      #domains = [ ];
    };
  };

  system.stateVersion = "23.11";
}
