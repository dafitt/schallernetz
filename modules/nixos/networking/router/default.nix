{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.networking.router;
in
{
  options.schallernetz.networking.router = with types; {
    enable = mkBoolOpt false "Enable the schallernetz router configuration.";
  };

  config = mkIf cfg.enable {
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
          IPForward = true;
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/60"; # ask for prefix delegation
        };
      };

      networks."60-untrusted" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "1";
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
      };

      networks."60-lan" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "2";
        ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "***REMOVED_IPv6***::/64"; }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          DNS = "***REMOVED_IPv6***";
          Domains = [ "***REMOVED_DOMAIN***" "lan.***REMOVED_DOMAIN***" ];
        };
      };

      networks."60-server" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "c";
        ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "***REMOVED_IPv6***::/64"; }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
      };

      networks."60-dmz" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "d";
        ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "***REMOVED_IPv6***::/64"; }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
      };

      networks."60-lab" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "e";
        ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "***REMOVED_IPv6***::/64"; }];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
        };
      };

      networks."60-management" = {
        # NOTE completion of bridge
        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        dhcpPrefixDelegationConfig.SubnetId = "f";
        ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "***REMOVED_IPv6***::/64"; }]; # to be able to ping ***REMOVED_IPv6*** from a client (automatic route configuration)
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
        };
      };
    };

    networking.nftables = {
      enable = true;

      tables."schallernetzFIREWALL" = {
        family = "inet";
        content = readFile ./schallernetzFIREWALL.nft;
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
}
