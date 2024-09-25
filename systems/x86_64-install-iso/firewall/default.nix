#$ nix build .#install-isoConfigurations.firewall
#$ cp result/iso/nixos-<version>.iso /dev/sdX

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ];

  schallernetz = {
    backups.localhost = false;
    backups.NAS4 = false;

    servers = {
      unbound.enable = true;
    };
  };

  isoImage.squashfsCompression = "zstd -Xcompression-level 5";
  boot.kernelParams = [ "copytoram" ];
  boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "vfat" "xfs" "ntfs" "cifs" ]; # remove ZFS support

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  # enable routing
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = false;
    "net.ipv6.conf.all.forwarding" = true;
  };

  systemd.network = {
    wait-online.anyInterface = true; # don't wait for all managed interfaces to come online and reach timeout

    # 10 = wan-interface
    # 20 = netdevs: bond, vlan, bridge
    # 30 = interfaces
    # 40 = bond-networks
    # 50 = vlan-networks
    # 60 = bridge-networks

    ### untrusted
    netdevs."20-vlan1" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan1";
      };
      vlanConfig.Id = 1;
    };
    networks."50-vlan1" = {
      matchConfig.Name = "vlan1";
      linkConfig.RequiredForOnline = "carrier";
      networkConfig.LinkLocalAddressing = "no";
    };
    netdevs."20-br-untrusted" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-untrusted";
      };
    };
    networks."60-br-untrusted" = {
      matchConfig.Name = "br-untrusted";
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
      dhcpPrefixDelegationConfig = {
        SubnetId = "01";
      };
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
    netdevs."20-vlan2" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan2";
      };
      vlanConfig.Id = 2;
    };
    networks."50-vlan2" = {
      matchConfig.Name = "vlan2";
      linkConfig.RequiredForOnline = "carrier";
      networkConfig.LinkLocalAddressing = "no";
    };
    netdevs."20-br-lan" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-lan";
      };
    };
    networks."60-br-lan" = {
      matchConfig.Name = "br-lan";
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
      dhcpPrefixDelegationConfig = {
        SubnetId = "02";
      };
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
    netdevs."20-vlan12" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan12";
      };
      vlanConfig.Id = 12;
    };
    networks."50-vlan12" = {
      matchConfig.Name = "vlan12";
      linkConfig.RequiredForOnline = "carrier";
      networkConfig.LinkLocalAddressing = "no";
    };
    netdevs."20-br-server" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-server";
      };
    };
    networks."60-br-server" = {
      matchConfig.Name = "br-server";
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
      dhcpPrefixDelegationConfig = {
        SubnetId = "0c";
      };
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
    netdevs."20-vlan13" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan13";
      };
      vlanConfig.Id = 13;
    };
    networks."50-vlan13" = {
      matchConfig.Name = "vlan13";
      linkConfig.RequiredForOnline = "carrier";
      networkConfig.LinkLocalAddressing = "no";
    };
    netdevs."20-br-dmz" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-dmz";
      };
    };
    networks."60-br-dmz" = {
      matchConfig.Name = "br-dmz";
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
      dhcpPrefixDelegationConfig = {
        SubnetId = "0d";
      };
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
    netdevs."20-vlan15" = {
      netdevConfig = {
        Kind = "vlan";
        Name = "vlan15";
      };
      vlanConfig.Id = 15;
    };
    networks."50-vlan15" = {
      matchConfig.Name = "vlan15";
      linkConfig.RequiredForOnline = "carrier";
      networkConfig.LinkLocalAddressing = "no";
    };
    netdevs."20-br-management" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br-management";
      };
    };
    networks."60-br-management" = {
      matchConfig.Name = "br-management";
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
        Bridge = "br-lan"; # untagged
        LinkLocalAddressing = "no";
        #ConfigureWithoutCarrier = true;
      };
    };
    networks."30-enp2s0" = {
      matchConfig.Name = "enp2s0";
      linkConfig.RequiredForOnline = "enslaved";
      vlan = [ "vlan12" "vlan13" ]; # tagged
      networkConfig = {
        Bridge = "br-lan"; # untagged
        LinkLocalAddressing = "no";
        #ConfigureWithoutCarrier = true;
      };
    };
    networks."30-enp3s0" = {
      matchConfig.Name = "enp3s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "br-management"; # untagged
        LinkLocalAddressing = "no";
        #ConfigureWithoutCarrier = true;
      };
    };
    ### wan
    networks."10-enp4s0" = {
      matchConfig.Name = "enp4s0";
      linkConfig.RequiredForOnline = "routable"; # make routing on this interface a dependency for network-online.target
      networkConfig = {
        # start a DHCP Client for IPv4 Addressing/Routing
        DHCP = "ipv4";
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

          ct state { established, related } accept     comment "Allow established traffic."

          #ip protocol icmp icmp type { destination-unreachable, echo-request, time-exceeded, parameter-problem } accept     comment "Allow select ICMP."
          ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, echo-request, time-exceeded, parameter-problem, packet-too-big } accept     comment "Allow select ICMPv6."

          iifname { "lo" } accept     comment "Accept everything from loopback interface. Allows itself to reach the internet."

          iifname { "br-management" } accept     comment "Allow management-network to access the router"
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          ct state { established, related }     comment "Allow established traffic."

          iifname { "br-lan" } oifname { "wan" } accept
          iifname { "wan" } oifname { "br-lan" } ct state { established, related } accept     comment "Allow established back to LANs"
        }
      }

      #table ip nat {
      #  chain postrouting {
      #    type nat hook postrouting priority 100; policy accept;
      #    oifname { "wan" } masquerade
      #  }
      #}
    '';
  };

  system.stateVersion = "24.05";
}
