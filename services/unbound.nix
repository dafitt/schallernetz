{ config, ... }: {
  #$ sudo nixos-container start unbound
  #$ sudo nixos-container root-login undbound

  containers."unbound" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";
    localAddress6 = "***REMOVED_IPv6***/64";

    specialArgs = { hostconfig = config; };
    config = { hostconfig, lib, ... }: {

      # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
      # It is designed to be fast and lean and incorporates modern features based on open standards.
      services.unbound = {
        enable = true;

        settings.server = {
          # the interface ip's that is used to connect to the network
          interface = [
            "***REMOVED_IPv4***"
            "***REMOVED_IPv6***"
            "***REMOVED_IPv6***"
          ];

          # IP ranges that are allowed to connect to the resolver
          access-control = [ "***REMOVED_IPv4***/16 allow" "***REMOVED_IPv6***::/56 allow" ];

          # DNS-Zones that unbound can resolve
          local-zone = [
            "${hostconfig.networking.domain} static"
          ];
          local-data = with hostconfig.networking; [
            ''"${domain}. IN NS unbound.${domain}"''
            ''"${domain}. IN SOA ${domain}. nobody.email. 1 3600 1200 604800 10800"''

            ''"fritzbox.${domain}. IN AAAA ***REMOVED_IPv6***"''
            ''"pihole.${domain}. IN AAAA ***REMOVED_IPv6***"''
            ''"unbound.${domain}. IN AAAA ***REMOVED_IPv6***"''
            ''"searx.${domain}. IN A ***REMOVED_IPv4***"''
            ''"searx.${domain}. IN AAAA ***REMOVED_IPv6***"''

            ''"minisforumhm80.${domain}. IN AAAA ***REMOVED_IPv6***"''
            ''"DavidSYNC.${domain}. IN AAAA ***REMOVED_IPv6***"''
            ''"DavidCAL.${domain}. IN AAAA ***REMOVED_IPv6***"''

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
              "${hostconfig.networking.defaultGateway.address}"
              #"${hostconfig.networking.defaultGateway6.address}" #! fe80::
            ];
          }
        ];
      };

      networking = {

        # automatically get IP and default gateway
        useDHCP = lib.mkForce true;
        enableIPv6 = true;

        #defaultGateway = hostconfig.networking.defaultGateway.address;
        #defaultGateway6 = hostconfig.networking.defaultGateway6.address;

        firewall.interfaces."eth0" = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
      };

      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;

      system.stateVersion = "23.11";
    };
  };
}
