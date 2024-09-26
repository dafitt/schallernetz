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
          Bridge = "untrusted-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-untrusted-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "untrusted-bridge";
        };
      };
      networks."60-untrusted-bridge" = {
        matchConfig.Name = "untrusted-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };
        dhcpPrefixDelegationConfig.SubnetId = "1";
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          #EmitDNS = true;
          #DNS = "***REMOVED_IPv6***";
          #EmitDomains = true;
          #Domains = [
          #  "guest.lossy.network"
          #];
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
          Bridge = "lan-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-lan-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "lan-bridge";
        };
      };
      networks."60-lan-bridge" = {
        matchConfig.Name = "lan-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };
        dhcpPrefixDelegationConfig.SubnetId = "2";
        ipv6Prefixes = [{
          ipv6PrefixConfig = {
            Prefix = "***REMOVED_IPv6***::/64";
          };
        }];
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          #EmitDNS = true;
          #DNS = "***REMOVED_IPv6***";
          #EmitDomains = true;
          #Domains = [
          #  "lan.lossy.network"
          #];
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
          Bridge = "server-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-server-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "server-bridge";
        };
      };
      networks."60-server-bridge" = {
        matchConfig.Name = "server-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };
        dhcpPrefixDelegationConfig.SubnetId = "c";
        ipv6Prefixes = [{
          ipv6PrefixConfig = {
            Prefix = "***REMOVED_IPv6***::/64";
          };
        }];
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          #EmitDNS = true;
          #DNS = "***REMOVED_IPv6***";
          #EmitDomains = true;
          #Domains = [
          #  "lan.lossy.network"
          #];
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
          Bridge = "dmz-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-dmz-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "dmz-bridge";
        };
      };
      networks."60-dmz-bridge" = {
        matchConfig.Name = "dmz-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };
        dhcpPrefixDelegationConfig.SubnetId = "d";
        ipv6Prefixes = [{
          ipv6PrefixConfig = {
            Prefix = "***REMOVED_IPv6***::/64";
          };
        }];
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          #EmitDNS = true;
          #DNS = "***REMOVED_IPv6***";
          #EmitDomains = true;
          #Domains = [
          #  "lan.lossy.network"
          #];
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
          Bridge = "lab-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-lab-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "lab-bridge";
        };
      };
      networks."60-lab-bridge" = {
        matchConfig.Name = "lab-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };
        dhcpPrefixDelegationConfig.SubnetId = "e";
        ipv6Prefixes = [{
          ipv6PrefixConfig = {
            Prefix = "***REMOVED_IPv6***::/64";
          };
        }];
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          #EmitDNS = true;
          #DNS = "***REMOVED_IPv6***";
          #EmitDomains = true;
          #Domains = [
          #  "lan.lossy.network"
          #];
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
          Bridge = "management-bridge";
          LinkLocalAddressing = "no";
        };
      };
      netdevs."20-management-bridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "management-bridge";
        };
      };
      networks."60-management-bridge" = {
        matchConfig.Name = "management-bridge";
        linkConfig.RequiredForOnline = "routable";
        bridgeConfig = { };

        address = [
          "***REMOVED_IPv4***/24"
          "***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
      };

      # connect the physical interfaces to the right bridge and/or vlan
      networks."30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = "lan-bridge"; # untagged
          LinkLocalAddressing = "no";
          #ConfigureWithoutCarrier = true;
        };
      };
      networks."30-enp2s0" = {
        matchConfig.Name = "enp2s0";
        linkConfig.RequiredForOnline = "enslaved";
        vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
        networkConfig = {
          Bridge = "lan-bridge"; # untagged
          LinkLocalAddressing = "no";
          #ConfigureWithoutCarrier = true;
        };
      };
      networks."30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = "management-bridge"; # untagged
          LinkLocalAddressing = "no";
          #ConfigureWithoutCarrier = true;
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
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0; policy drop;

            ct state { established, related } accept  comment "Allow established traffic."

            #ip protocol icmp icmp type { destination-unreachable, echo-request, time-exceeded, parameter-problem } accept  comment "Allow select ICMP."
            ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, echo-request, time-exceeded, parameter-problem, packet-too-big } accept  comment "Allow select ICMPv6."

            iifname { "lo" } accept  comment "Accept everything from loopback interface. Allows itself to reach the internet."

            iifname { "management-bridge" } accept  comment "Allow management-network to access the router"
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            ct state { established, related }  comment "Allow established traffic."

            iifname { "lan-bridge" } oifname { "enp4s0" } accept
            iifname { "enp4s0" } oifname { "lan-bridge" } ct state { established, related } accept  comment "Allow established back to LANs"
          }
        }

        #table ip nat {
        #  chain postrouting {
        #    type nat hook postrouting priority 100; policy accept;
        #    oifname { "enp4s0" } masquerade
        #  }
        #}
      '';
    };
  };
}
