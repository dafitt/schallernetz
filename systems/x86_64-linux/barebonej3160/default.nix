# Installation with install-iso anywhere
#$ nix run github:nix-community/nixos-anywhere -- --flake .#barebonej3160 root@***REMOVED_IPv6***%<enp?s0>
# Rebuild
#$ nixos-rebuild --flake .#barebonej3160 --use-remote-sudo --target-host rebuild@barebonej3160.lan.***REMOVED_DOMAIN*** [--build-host rebuild@barebonej3160.lan.***REMOVED_DOMAIN***] <test|boot|switch>

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = with inputs; [
    ./hardware-configuration.nix
    ../../global-configuration.nix

    disko.nixosModules.disko
    ./disk-configuration.nix
  ];

  schallernetz = {
    networking.router.enable = true;

    servers = {
      unbound.enable = true;
      adguardhome.enable = true;
      wireguard-lan.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  #systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  systemd.network.networks = {
    "30-enp1s0" = {
      matchConfig.Name = "enp1s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "wan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp2s0" = {
      matchConfig.Name = "enp2s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "lan"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp3s0" = {
      matchConfig.Name = "enp3s0";
      linkConfig.RequiredForOnline = "enslaved";
      vlan = [ "server-vlan" "dmz-vlan" ]; # tagged
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };
    "30-enp4s0" = {
      matchConfig.Name = "enp4s0";
      linkConfig.RequiredForOnline = "enslaved";
      networkConfig = {
        Bridge = "management"; # untagged
        LinkLocalAddressing = "no";
      };
    };

    "60-wan" = {
      # NOTE completion of bridge
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
      };
      ipv6AcceptRAConfig = {
        UseDNS = false; # I handle DNS myself.
      };
      dhcpV6Config = {
        PrefixDelegationHint = "::/60"; # Ask for prefix delegation.
        UseAddress = false; # Generate my own IPv6.
        UseDNS = false; # I handle DNS myself.
        WithoutRA = "solicit";
      };
    };

    "60-untrusted" = with config.schallernetz.networking.subnets.untrusted; {
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

    "60-lan" = with config.schallernetz.networking.subnets.lan; {
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

    "60-server" = with config.schallernetz.networking.subnets.server; {
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

    "60-dmz" = with config.schallernetz.networking.subnets.dmz; {
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

    "60-management" = with config.schallernetz.networking.subnets.management; {
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

  boot.loader.timeout = 0;
  boot.loader.grub.configurationLimit = 5;

  # improve performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  services.irqbalance.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "24.05";
}
