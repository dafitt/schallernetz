{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.networking;
in
{
  options.schallernetz.networking = with types; {
    enable = mkBoolOpt true "Enable network configuration.";

    uniqueLocalPrefix = mkOption {
      type = types.str;
      default = "***REMOVED_IPv6***";
      example = "***REMOVED_IPv6***";
      description = lib.mdDoc ''
        IPv6 Unique Local Address prefix (ULA prefix). Only intended
        for usage in your config: `$\{config.schallernetz.networking.uniqueLocalPrefix}`
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = host;
      domain = "***REMOVED_DOMAIN***";

      #nameservers = mkAfter [ config.schallernetz.containers.unbound.ipv6address ]; #FIXME ping ***REMOVED_IPv6*** doesn't work with this
    };

    networking.useDHCP = false;
    systemd.network = {
      enable = true;
      # bridge
      netdevs."20-br_lan".netdevConfig = {
        Kind = "bridge";
        Name = "br_lan";
      };
      networks."40-br_lan" = {
        matchConfig.Name = "br_lan";
        bridgeConfig = { };
        linkConfig.RequiredForOnline = "routable";

        networkConfig = {
          IPv6AcceptRA = true; # for ipv6 dynamic gateway route
        };
        # NOTE completion of bridge per host required:
        #address = [];
        #gateway = []; # not for ipv6
        #dns = [];
        #domains = [ ];
      };
    };
  };
}
