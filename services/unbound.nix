{
  #$ sudo nixos-container start DavidVPN
  #$ sudo nixos-container root-login DavidVPN

  containers."unbound" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";

    config = { lib, ... }: {

      # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
      # It is designed to be fast and lean and incorporates modern features based on open standards.

      services.unbound = {
        enable = true;

        settings.server = {
          # the interface ip's that is used to connect to the network
          interface = [ "***REMOVED_IPv4***" ];

          # IP ranges that are allowed to connect to the resolver
          access-control = [ "***REMOVED_IPv4***/16 allow" ];

          # DNS-Zones that unbound can resolve
          local-zone = [
            "schallernetz.local static"
          ];
          local-data = [
            ''"pihole.schallernetz.local. IN A ***REMOVED_IPv4***"''
          ];

          #settings.forward-zone = [
          #  {
          #    name = ".fritz.box";
          #    forward-addr = "***REMOVED_IPv4***";
          #  }
          #];
        };
      };

      networking.firewall.interfaces."eth0" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };

      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;

      system.stateVersion = "23.11";
    };
  };
}
