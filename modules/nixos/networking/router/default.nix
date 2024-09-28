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
      # 10 = wan-interface
      # 20 = netdevs: bond, vlan, bridge
      # 30 = interfaces
      # 40 = bond-networks
      # 50 = vlan-networks
      # 60 = bridge-networks

      ### untrusted
      netdevs."20-untrusted-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "untrusted-vlan";
        };
        vlanConfig.Id = 1;
      };
      networks."50-untrusted-vlan" = {
        matchConfig.Name = "untrusted-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          ConfigureWithoutCarrier = true;
          Bridge = "untrusted-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-untrusted-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "untrusted-br";
        };
      };
      networks."60-untrusted-br" = {
        matchConfig.Name = "untrusted-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      ### lan
      netdevs."20-lan-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "lan-vlan";
        };
        vlanConfig.Id = 2;
      };
      networks."50-lan-vlan" = {
        matchConfig.Name = "lan-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          Bridge = "lan-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-lan-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "lan-br";
        };
        #bridgeConfig = {
        #  # https://docs.bisdn.de/network_configuration/vlan_bridging.html#systemd-networkd-1
        #  VLANFiltering = true;
        #  DefaultPVID = 2;
        #};
      };
      networks."60-lan-br" = {
        matchConfig.Name = "lan-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      ### server
      netdevs."20-server-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "server-vlan";
        };
        vlanConfig.Id = 12;
      };
      networks."50-server-vlan" = {
        matchConfig.Name = "server-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          ConfigureWithoutCarrier = true;
          Bridge = "server-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-server-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "server-br";
        };
      };
      networks."60-server-br" = {
        matchConfig.Name = "server-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      ### dmz
      netdevs."20-dmz-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "dmz-vlan";
        };
        vlanConfig.Id = 13;
      };
      networks."50-dmz-vlan" = {
        matchConfig.Name = "dmz-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          Bridge = "dmz-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-dmz-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "dmz-br";
        };
      };
      networks."60-dmz-br" = {
        matchConfig.Name = "dmz-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      ### lab
      netdevs."20-lab-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "lab-vlan";
        };
        vlanConfig.Id = 14;
      };
      networks."50-lab-vlan" = {
        matchConfig.Name = "lab-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          Bridge = "lab-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-lab-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "lab-br";
        };
      };
      networks."60-lab-br" = {
        matchConfig.Name = "lab-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      ### management
      netdevs."20-management-vlan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "management-vlan";
        };
        vlanConfig.Id = 15;
      };
      networks."50-management-vlan" = {
        matchConfig.Name = "management-vlan";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          Bridge = "management-br";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-management-br" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "management-br";
        };
      };
      networks."60-management-br" = {
        matchConfig.Name = "management-br";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

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

      # connect the physical interfaces to the right bridge and/or vlan
      networks."30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = "lan-br"; # untagged
          LinkLocalAddressing = "no";
        };
      };
      networks."30-enp2s0" = {
        matchConfig.Name = "enp2s0";
        linkConfig.RequiredForOnline = "enslaved";
        vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
        networkConfig = {
          Bridge = "lan-br"; # untagged
          LinkLocalAddressing = "no";
        };
      };
      networks."30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = "management-br"; # untagged
          LinkLocalAddressing = "no";
        };
      };
      ### wan
      networks."10-enp4s0" = {
        matchConfig.Name = "enp4s0";
        linkConfig.RequiredForOnline = "routable"; # make routing on this interface a dependency for network-online.target
        networkConfig = {
          DHCP = "ipv4"; # start a DHCP Client for IPv4 Addressing/Routing
          DNSOverTLS = true;
          DNSSEC = true;
          IPv6PrivacyExtensions = true;
          IPForward = true;
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
      #      oifname { "enp4s0" } masquerade
      #    }
      #  '';
      #};
    };
  };
}
