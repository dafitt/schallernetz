{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.networking.router;
  subnetsCfg = config.schallernetz.networking.subnets;
in
{
  options.schallernetz.networking.router = with types; {
    enable = mkBoolOpt false "Enable the schallernetz router configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      termshark
    ];

    # enable routing
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = false;
      "net.ipv6.conf.all.forwarding" = true;
    };

    systemd.network = {
      networks."60-wan" = {
        # NOTE completion of bridge
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          DNSOverTLS = true;
          DNSSEC = true;
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/60"; # ask for prefix delegation
        };
      };

      networks."60-untrusted" = with subnetsCfg.untrusted; {
        # NOTE completion of bridge
        address = [
          #"***REMOVED_IPv4***/16"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = prefixId;
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.adguardhome.ip6Address ];
        };
      };

      networks."60-lan" = with subnetsCfg.lan; {
        # NOTE completion of bridge
        address = [
          #" ***REMOVED_IPv4***/16 "
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = prefixId;
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.adguardhome.ip6Address ];
        };
      };

      networks."60-server" = with subnetsCfg.server; {
        # NOTE completion of bridge
        address = [
          #"***REMOVED_IPv4***/16"
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = prefixId;
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.unbound.ip6Address ];
        };
      };

      networks."60-dmz" = with subnetsCfg.dmz; {
        # NOTE completion of bridge
        address = [
          #"***REMOVED_IPv4***/16"
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = prefixId;
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
      };

      networks."60-management" = with subnetsCfg.management; {
        # NOTE completion of bridge
        address = [
          #"***REMOVED_IPv4***/16"
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = prefixId;
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }]; # to be able to ping ***REMOVED_IPv6*** from a client (automatic route configuration)
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
        };
      };
    };
#systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    networking = {
      nat.enable = false;
      firewall.enable = false; # Use nftables instead.
      nftables = {
      enable = true;

      tables."schallernetzFIREWALL" = {
        family = "inet";
        content = readFile ./schallernetzWALL.nft;
      };
      #tables."schallernetzNATv4" = {
      #  family = "ip";
      #  content = ''
      #    chain postrouting {
      #      type nat hook postrouting priority srcnat; policy accept;
      #      oifname { "wan" } masquerade
      #    }
      #  '';
      #};
      };
    };
  };
}
