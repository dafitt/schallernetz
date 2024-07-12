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
    ipv6address = mkOpt str "***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {

    #$ sudo nixos-container start unbound
    #$ sudo nixos-container root-login unbound
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "${cfg.ipv6address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {

        # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
        # It is designed to be fast and lean and incorporates modern features based on open standards.
        services.${cfg.name} = {
          enable = true;

          settings.server = {
            # the interface ip's that is used to connect to the network
            interface = [
              "***REMOVED_IPv4***"
              "${cfg.ipv6address}"
              "***REMOVED_IPv6***"
            ];

            # IP ranges that are allowed to connect to the resolver
            access-control = [ "***REMOVED_IPv4***/16 allow" "***REMOVED_IPv6***::/56 allow" ];

            # DNS-Zones that unbound can resolve
            local-zone = [
              "${hostConfig.networking.domain} static"
            ];
            local-data =
              with hostConfig.networking; # .domain
              let
                minisforumhm80 = "***REMOVED_IPv6***"; # Workaround for CNAME
              in
              [
                ''"${domain}. IN NS ${cfg.name}.${domain}"''
                ''"${domain}. IN SOA ${domain}. nobody.email. 1 3600 1200 604800 10800"''

                ''"${cfg.name}.${domain}. IN AAAA ${cfg.ipv6address}"''
                ''"fritzbox.${domain}. IN AAAA ***REMOVED_IPv6***"''
                ''"adguard.${domain}. IN AAAA ${minisforumhm80}"''
                ''"bitwarden.${domain}. IN AAAA ${minisforumhm80}"''
                ''"ntfy.${domain}. IN AAAA ${minisforumhm80}"''
                ''"searx.${domain}. IN AAAA ${minisforumhm80}"''

                ''"minisforumhm80.${domain}. IN AAAA ${minisforumhm80}"''
                ''"minisforumhm80.${domain}. IN A ***REMOVED_IPv4***"''
                ''"DavidSYNC.${domain}. IN AAAA ${minisforumhm80}"''
                ''"DavidCAL.${domain}. IN AAAA ${minisforumhm80}"''

                ''"MichiSHARE.${domain}. IN A ***REMOVED_IPv4***"''
                ''"MichiSHARE.${domain}. IN AAAA ***REMOVED_IPv6***"''
                ''"nas1.${domain}. IN A ***REMOVED_IPv4***"''
                ''"nas2.${domain}. IN A ***REMOVED_IPv4***"''
              ];
          };

          settings.forward-zone = [
            {
              name = "fritz.box";
              forward-addr = [
                "${hostConfig.networking.defaultGateway.address}"
                "${hostConfig.networking.defaultGateway6.address}" #! [fe80::]:53 (link-local) is refused
              ];
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
            allowedTCPPorts = [ 53 ];
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
