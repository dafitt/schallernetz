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

    wan = mkOption {
      type = str;
      default = "wan";
      description = "The name of the wan network (interface or bridge).";
      example = "eth0";
    };

    extraNfrules_in = mkOption {
      type = listOf str;
      # Some default, if you forget to set it. Hopefully you also picked "lan" as your subnet-name, then.
      default = [
        "iifname lan tcp dport 22 accept"
        "iifname management accept"
      ];
      description = "Additional nftables rules of what to allow into the router.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dig
      termshark
      traceroute
    ];

    # enable routing
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = false;
      "net.ipv6.conf.all.forwarding" = true;
    };

    systemd.network = {
      networks."10-wan" = {
        matchConfig.Name = cfg.wan;
        linkConfig.RequiredForOnline = "routable";

        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          #IPMasquerade  = "ipv4";
          IPForward = true; # TODO 24.11: IPv4Forwarding = true;
          IPv6PrivacyExtensions = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false; # I handle DNS myself.
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/60"; # Ask for prefix delegation.
          UseAddress = false; # Generate my own IPv6.
          UseDNS = false; # I handle DNS myself.
          WithoutRA = "solicit"; # information-request
        };
      };

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
          "${uniqueLocal.prefix}***REMOVED_IPv6***/64"
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
          ipv6PrefixConfig.Prefix = "${uniqueLocal.prefix}::/64";
        }];
      };

      networks."60-server" = with subnetsCfg.server; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocal.prefix}***REMOVED_IPv6***/64"
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
          ipv6PrefixConfig.Prefix = "${uniqueLocal.prefix}::/64";
        }];
      };

      networks."60-dmz" = with subnetsCfg.dmz; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocal.prefix}***REMOVED_IPv6***/64"
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
          ipv6PrefixConfig.Prefix = "${uniqueLocal.prefix}::/64";
        }];
      };

      networks."60-management" = with subnetsCfg.management; {
        # NOTE completion of bridge
        address = [
          "${uniqueLocal.prefix}***REMOVED_IPv6***/64"
          "***REMOVED_IPv6***/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
        };
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "${uniqueLocal.prefix}::/64";
        }]; # to be able to ping ***REMOVED_IPv6*** from a client (automatic route configuration)
      };
    };
    #systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

    networking = {
      # NAT64 in combination with DNS64 (->unbound).
      jool = {
        enable = true;
        nat64.default.global.pool6 = "***REMOVED_IPv6***::/96";
      };

      firewall.enable = false; # We use nftables instead.
      nftables = {
        enable = true;

        tables."schallernetzFIREWALL" = {
          family = "inet";

          # https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes
          content = ''
            # Everything that is beeing sent to this host.
            chain input {
              type filter hook input priority filter + 1; policy drop;

              ct state invalid drop # Drop invalid connections.
              ct state { established, related } accept # Allow established traffic.

              iifname ${cfg.wan} udp dport 546 accept # dhcpv6-client

              icmp type echo-request accept # Allow ping.
              icmpv6 type != { nd-redirect, 139 } accept # Accept all ICMPv6 messages except redirects and node information queries (type 139).  See RFC 4890, section 4.4.

              iifname lo accept # Accept everything from loopback interface. Allows itself to reach the internet.

              ${concatStringsSep "\n" cfg.extraNfrules_in}
            }

            # Everything that is beeing forwarded from one interface to another.
            chain forward { # Everything that is beeing forwarded.
              type filter hook forward priority filter; policy drop;

              ct state invalid drop # Drop invalid packets.
              ct state established,related accept # Allow established traffic.

              # https://wiki.nftables.org/wiki-nftables/index.php/Classic_perimetral_firewall_example
              oifname vmap {
                ${concatStrings (forEach (attrValues config.schallernetz.networking.subnets) (subnet: ''
                  ${subnet.name}: jump ${subnet.name}_in,''))}
              }
            }

            ${concatStringsSep "\n" (forEach (attrValues config.schallernetz.networking.subnets) (subnet: ''
              chain ${subnet.name}_in {
                ${concatStringsSep "\n" subnet.nfrules_in}
              }''))}
          '';
        };
      };
    };
  };
}
