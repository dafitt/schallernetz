#nix-repl> nixosConfigurations.minisforumhm80.config

#$ nix build .#nixosConfigurations.minisforumhm80.config.system.build.toplevel

#$ nixos-rebuild --flake .#minisforumhm80 --use-remote-sudo --target-host rebuild@minisforumhm80.***REMOVED_DOMAIN*** <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  #$ nix run .#apps.nixinate.minisforumhm80[-dry-run]
  _module.args.nixinate = {
    host = "minisforumhm80.***REMOVED_DOMAIN***";
    sshUser = "rebuild";
    buildOn = "local";
    substituteOnTarget = true;
  };

  schallernetz = {
    containers = {
      adguard.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      DavidVPN.enable = true;
      gitea.enable = true;
      MichiSHARE.enable = true;
      ntfy.enable = true;
      searx.enable = true;
      unbound.enable = true;
      bitwarden.enable = true;
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

  system.stateVersion = "23.11";
}
