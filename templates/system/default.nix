# Check:
#$ nix flake check
#$ nixos-rebuild repl --fast --flake .#<host>

# Build:
#$ nixos-rebuild build --fast --flake .#<host>
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Activate:
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

    servers.adguardhome.enable = false;
    servers.adguardhome.name = "adguardhome";
    servers.adguardhome.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.bitwarden.enable = false;
    servers.bitwarden.name = "bitwarden";
    servers.bitwarden.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.DavidCAL.enable = false;
    servers.DavidCAL.name = "DavidCAL";
    servers.DavidCAL.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.DavidSYNC.enable = false;
    servers.DavidSYNC.name = "DavidSYNC";
    servers.DavidSYNC.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.DavidVPN.enable = false;
    servers.DavidVPN.name = "DavidVPN";
    servers.forgejo.enable = false;
    servers.forgejo.name = "forgejo";
    servers.forgejo.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.haproxy.enable = false;
    servers.haproxy.name = "haproxy";
    servers.haproxy.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.MichiSHARE.enable = false;
    servers.MichiSHARE.name = "MichiSHARE";
    servers.MichiSHARE.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.ntfy.enable = false;
    servers.ntfy.name = "ntfy";
    servers.ntfy.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.searx.enable = false;
    servers.searx.name = "searx";
    servers.searx.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";
    servers.unbound.enable = false;
    servers.unbound.name = "unbound";
    servers.unbound.ipv6Address = "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***";

    environment.enable = true;

    locale.enable = true;

    networking.enable = true;

    nix.enable = true;

    ntfy-systemd.enable = true;
    ntfy-systemd.url = "https://ntfy.***REMOVED_DOMAIN***";

    ssh.enable = true;

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
