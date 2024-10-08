{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.networking;
in
{
  options.schallernetz.networking = with types; {
    enable = mkBoolOpt true ''Enable network configuration.
      All of my networking options should be set equally for each systems/.
      Recommendation:
        1. Define all my networking options in _`systems/network-configuration.nix`_ and
        2. import this file to each system with `imports = [ ../../network-configuration.nix ];`.
    '';

    domain = mkOption {
      type = str;
      description = "The domain name of the network.";
      example = "***REMOVED_DOMAIN***";
    };

    uniqueLocal = {
      prefix_ = mkOption {
        type = str;
        description = ''
          The incomplete IPv6 Unique Local Address prefix (ULA prefix).
          Something from fc00::/7.
        '';
        example = "***REMOVED_IPv6***";
      };
      prefix = mkOption {
        type = str;
        description = ''
          The complete IPv6 Unique Local Address prefix (ULA prefix).
          Something from fc00::/7.
        '';
        example = "${prefix_}0";
      };
      suffix = mkOption {
        type = ints.between 7 64;
        description = ''
          IPv6 Unique Local Address suffix (ULA suffix).
          Something between /7 and /64.
        '';
        example = 60;
      };
    };

    subnets = mkOption {
      type = attrsOf (submodule ({ name, ... }:
        let
          cfg = config.schallernetz.networking.subnets.${name};
        in
        {
          options = {
            name = mkOption {
              type = strMatching "[a-zA-Z0-9_-]{1,10}";
              default = name;
              example = "server";
              description = "Name of the subnet. Must not exceed 11 characters.";
            };

            prefixId = mkOption {
              type = nullOr str;
              default = null;
              example = "c";
              description = "The subnet's ipv6 prefix id.";
            };

            uniqueLocal = {
              prefix = mkOption {
                type = nullOr str;
                default = if cfg.prefixId != null then "${config.schallernetz.networking.uniqueLocal.prefix_}${cfg.prefixId}" else null;
                description = ''
                  The prefix of the subnet. It is generated automatically
                  from the uniqueLocal.prefix and the prefixId.
                '';
              };
              suffix = mkOption {
                type = ints.between 7 64;
                default = 64;
                description = "One subnet is usually /64.";
              };
            };

            vlan = mkOption {
              type = ints.between 1 4094;
              example = 12;
              description = "The subnet's vlan id.";
            };

            nfrules_in = mkOption {
              type = listOf str;
              default = [ ];
              description = "nftables rules of what to allow into the subnet.";
            };
          };
        }));
      description = "The subnets of the network.";
      example = {
        "untrusted" = { prefixId = "1"; vlan = 1; };
        "lan" = { prefixId = "2"; vlan = 2; };
        "server" = { prefixId = "c"; vlan = 12; };
        "dmz" = { prefixId = "d"; vlan = 13; };
        "management" = { prefixId = "f"; vlan = 15; };
      };
    };
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = host;
      domain = cfg.domain;

      nameservers = [ config.schallernetz.servers.unbound.ip6Address ];
    };

    networking.useDHCP = false;
    systemd.network = {
      enable = true;
      wait-online.anyInterface = true; # don't wait for all managed interfaces to come online and reach timeout

      # Priority:
      # 10 = wan-interface
      # 20 = netdevs: bond, vlan, bridge
      # 30 = interfaces
      # 40 = bond-networks
      # 50 = vlan-networks
      # 60 = bridge-networks

      #netdevs."20-${subnet.name}-vlan" = {
      #  netdevConfig = {
      #    Kind = "vlan";
      #    Name = "${subnet.name}-vlan";
      #  };
      #  vlanConfig.Id = ${subnet.vlan};
      #};
      #netdevs."20-${subnet.bridge}" = {
      #  netdevConfig = {
      #    Kind = "bridge";
      #    Name = "${subnet.bridge}";
      #  };
      #};
      netdevs = listToAttrs (
        (forEach (attrValues cfg.subnets) (subnet: {
          name = "20-${subnet.name}-vlan";
          value = {
            netdevConfig = {
              Kind = "vlan";
              Name = "${subnet.name}-vlan";
            };
            vlanConfig.Id = subnet.vlan;
          };
        }))
        ++
        (forEach (attrValues cfg.subnets) (subnet: {
          name = "20-${subnet.name}";
          value = {
            netdevConfig = {
              Kind = "bridge";
              Name = "${subnet.name}";
            };
          };
        }))
      );

      #networks."50-${s.name}-vlan" = {
      #  matchConfig.Name = "${s.name}-vlan";
      #  linkConfig.RequiredForOnline = "carrier";
      #  networkConfig = {
      #    ConfigureWithoutCarrier = true;
      #    Bridge = "${s.bridge}";
      #    LinkLocalAddressing = "no";
      #  };
      #};
      #networks."60-${s.bridge}" = {
      #  matchConfig.Name = "${s.bridge}";
      #  linkConfig.RequiredForOnline = "routable";
      #
      #  # NOTE completion of bridge per host required:
      #  address = [];
      #  gateway = []; # not for ipv6
      #  dns = [];
      #  domains = [ ];
      #  networkConfig = {
      #    IPv6AcceptRA = true; # for ipv6 dynamic gateway route
      #  };
      #};
      networks = listToAttrs (
        (forEach (attrValues cfg.subnets) (subnet: {
          name = "50-${subnet.name}-vlan";
          value = {
            matchConfig.Name = "${subnet.name}-vlan";
            linkConfig.RequiredForOnline = "carrier";
            networkConfig = {
              ConfigureWithoutCarrier = true;
              Bridge = "${subnet.name}";
              LinkLocalAddressing = "no";
            };
          };
        }))
        ++
        (forEach (attrValues cfg.subnets) (subnet: {
          name = "60-${subnet.name}";
          value = {
            matchConfig.Name = "${subnet.name}";
            linkConfig.RequiredForOnline = "routable";

            domains = [ "${config.networking.domain}" "lan.${config.networking.domain}" ];
          };
        }))
      );

      ## NOTE don't forget to configure the interfaces in systems/
      #networks."30-enp2s0" = {
      #  matchConfig.Name = "enp2s0";
      #  linkConfig.RequiredForOnline = "enslaved";
      #  vlan = [ "lan-vlan" "server-vlan" "dmz-vlan" ]; # tagged
      #  networkConfig = {
      #    Bridge = "management"; # untagged
      #    LinkLocalAddressing = "no";
      #  };
      #};
    };
  };
}
