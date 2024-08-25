{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.unbound;
in
{
  options.schallernetz.containers.unbound = with types; {
    enable = mkBoolOpt false "Enable container unbound.";
    name = mkOpt str "unbound" "The name of the container.";
    ipv6address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start unbound
    #$ sudo nixos-container root-login unbound
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br_lan";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "${cfg.ipv6address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        environment.systemPackages = with pkgs; [ dig ];

        # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
        # It is designed to be fast and lean and incorporates modern features based on open standards.
        services.unbound = {
          enable = true;

          settings.server = {
            # the interface ip's that is used to connect to the network
            interface = [
              "***REMOVED_IPv4***"
              "${cfg.ipv6address}"
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

        networking = {
          # automatically get IP and default gateway
          useDHCP = mkForce true;
          enableIPv6 = true;

          #defaultGateway = hostConfig.networking.defaultGateway.address;
          #defaultGateway6 = hostConfig.networking.defaultGateway6.address;

          firewall.interfaces."eth0" = {
            allowedUDPPorts = [ 53 ];
          };
        };

        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        networking.useHostResolvConf = mkForce false;

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
