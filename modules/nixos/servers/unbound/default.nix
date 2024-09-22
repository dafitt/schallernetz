{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.unbound;
in
{
  options.schallernetz.servers.unbound = with types; {
    enable = mkBoolOpt false "Enable server unbound.";
    name = mkOpt str "unbound" "The name of the server.";
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start unbound
    #$ sudo nixos-container root-login unbound
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br_lan";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "${cfg.ipv6Address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        imports = with inputs;[ self.nixosModules."ntfy-systemd" ];

        environment.systemPackages = with pkgs; [ dig ];

        # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
        # It is designed to be fast and lean and incorporates modern features based on open standards.
        services.unbound = {
          enable = true;

          settings.server = {
            # the interface ip's that is used to connect to the network
            interface = [
              "***REMOVED_IPv4***"
              "${cfg.ipv6Address}"
            ];

            # IP ranges that are allowed to connect to the resolver
            access-control = [ "***REMOVED_IPv4***/16 allow" "${hostConfig.schallernetz.networking.uniqueLocalPrefix}::/56 allow" ];

            qname-minimisation = true;
          };

          settings.auth-zone = [
            {
              name = "***REMOVED_DOMAIN***";
              zonefile = "${./db.***REMOVED_DOMAIN***}";
            }
          ];
        };
        systemd.services.unbound.unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        networking = {
          useDHCP = mkForce true; # automatically get IPv4 and default route
          enableIPv6 = true; # automatically get IPv6 and default route6
          useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          firewall.interfaces."eth0" = {
            allowedUDPPorts = [ 53 ];
          };
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
