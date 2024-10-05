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
      dig
    ];

    # enable routing
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = false;
      "net.ipv6.conf.all.forwarding" = true;
    };

    systemd.network = {
      networks."10-wan" = {
        linkConfig = {
          RequiredForOnline = "routable"; # make routing on this interface a dependency for network-online.target
        };
        networkConfig = {
          DHCP = "ipv6";
          IPv6AcceptRA = true;
          DHCPPrefixDelegation = true;
          #IPMasquerade  = "ipv4";
          #IPv4Forwarding = true;
          #IPv6Forwarding = true;
          IPv6PrivacyExtensions = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false; # I'll handle DNS myself, please.
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/60"; # ask for prefix delegation
          WithoutRA = "solicit"; # information-request
        };
        dhcpPrefixDelegationConfig = {
          UplinkInterface = ":self";
          SubnetId = "0";
          Announce = false;
        };
      };
      # NOTE don't forget to assign the wan network to the port in systems/ e.g.
      #networks."10-wan".matchConfig.Name = "enp1s0";

      networks."60-untrusted" = with subnetsCfg.untrusted; {
        # NOTE completion of bridge
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.adguardhome.ip6Address ];
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = "0x${prefixId}";
          Token = "***REMOVED_IPv6***";
        };
      };

      networks."60-lan" = with subnetsCfg.lan; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.adguardhome.ip6Address ];
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = "0x${prefixId}";
          Token = "***REMOVED_IPv6***";
        };
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
      };

      networks."60-server" = with subnetsCfg.server; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPPrefixDelegation = true;
          DNS = [ config.schallernetz.servers.unbound.ip6Address ];
          IPv6DuplicateAddressDetection = 1;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = "0x${prefixId}";
          Token = "***REMOVED_IPv6***";
        };
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
      };

      networks."60-dmz" = with subnetsCfg.dmz; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPPrefixDelegation = true;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = "0x${prefixId}";
          Token = "***REMOVED_IPv6***";
        };
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }];
      };

      networks."60-management" = with subnetsCfg.management; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocalPrefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
        };
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocalPrefix}::/64";
        }]; # to be able to ping ***REMOVED_IPv6*** from a client (automatic route configuration)
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
