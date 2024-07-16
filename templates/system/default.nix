# Check:
#$ nix flake check
#$ nix repl
#nix-repl> :lf .
#nix-repl> nixosConfigurations.<host>.config

# Build:
#$ flake build-system [#<host>]
#$ nixos-rebuild build --fast --flake .#<host> --show-trace
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Activate:
#$ flake <test|switch|boot> [#<host>]
#$ nixos-rebuild --flake .#<host> <test|switch|boot>
#$ nix run .#nixosConfigurations.<host>.config.system.build.toplevel

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  schallernetz = rec {
    backups.localhost = true;
    backups.NAS4 = true;
    backups.paths = [ ];

    containers.adguard.enable = false;
    containers.adguard.name = "adguard";
    containers.adguard.ipv6address = "***REMOVED_IPv6***";
    containers.bitwarden.enable = false;
    containers.bitwarden.name = "bitwarden";
    containers.bitwarden.ipv6address = "***REMOVED_IPv6***";
    containers.DavidCAL.enable = false;
    containers.DavidCAL.name = "DavidCAL";
    containers.DavidCAL.ipv6address = "***REMOVED_IPv6***";
    containers.DavidCAL.remoteBackups = true;
    containers.DavidSYNC.enable = false;
    containers.DavidSYNC.name = "DavidSYNC";
    containers.DavidSYNC.ipv6address = "***REMOVED_IPv6***";
    containers.DavidVPN.enable = false;
    containers.DavidVPN.name = "DavidVPN";
    containers.MichiSHARE.enable = false;
    containers.MichiSHARE.name = "MichiSHARE";
    containers.MichiSHARE.ipv6address = "***REMOVED_IPv6***";
    containers.ntfy.enable = false;
    containers.ntfy.name = "ntfy";
    containers.ntfy.ipv6address = "***REMOVED_IPv6***";
    containers.searx.enable = false;
    containers.searx.name = "searx";
    containers.searx.ipv6address = "***REMOVED_IPv6***";
    containers.unbound.enable = false;
    containers.unbound.name = "unbound";
    containers.unbound.ipv6address = "***REMOVED_IPv6***";

    environment.enable = true;

    locale.enable = true;

    networking.enable = true;

    nix.enable = true;

    services.haproxy.enable = true;
    services.haproxy.frontends.www.extraConfig = [ ];
    services.ssh.enable = true;

    time.enable = true;

    users.admin.enable = true;
    users.rebuild.enable = true;
    users.root.enable = true;
    users.root.allowSshPasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
  ];

  # add device-specific nixos configuration here #

  system.stateVersion = "24.05";
}
