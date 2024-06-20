#nix-repl> nixosConfigurations.minisforumhm80.config
#$ nix build .#nixosConfigurations.minisforumhm80.config.system.build.toplevel
#$ nixos-rebuild build --fast --flake .#minisforumhm80 --show-trace
#$ ssh-add ~/.ssh/minisforumhm80 && nixos-rebuild --flake .#minisforumhm80 --target-host admin@minisforumhm80.***REMOVED_DOMAIN*** --use-remote-sudo <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  schallernetz = {
    containers = {
      adguard.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      DavidVPN.enable = true;
      MichiSHARE.enable = true;
      ntfy.enable = true;
      searx.enable = true;
      unbound.enable = true;
    };
    services.haproxy.enable = true;
  };

  environment.systemPackages = with pkgs; [
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  services.fstrim.enable = true; # SSD

  networking = {
    # Gets in the way of static IP adressing
    networkmanager.enable = false;
    useDHCP = false;

    bridges."br0".interfaces = [ "enp4s0" ];
    interfaces."br0" = {
      ipv4.addresses = [{
        address = "***REMOVED_IPv4***";
        prefixLength = 23;
      }];
      ipv6.addresses = [{
        address = "***REMOVED_IPv6***";
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = "***REMOVED_IPv4***";
      interface = "br0";
    };
    defaultGateway6 = {
      address = "***REMOVED_IPv6***";
      interface = "br0";
    };

    # for local updates
    nameservers = [
      config.networking.defaultGateway.address
      config.networking.defaultGateway6.address
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "***REMOVED_SSH-PUBLICKEY*** david@DavidDESKTOP"
  ];

  system.stateVersion = "23.11";
}
