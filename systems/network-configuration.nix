{ config, lib, ... }: with lib; {

  schallernetz.networking = {
    enable = true;
    domain = "***REMOVED_DOMAIN***";

    uniqueLocal = rec {
      prefix_ = "***REMOVED_IPv6***";
      prefix = "${prefix_}0";
      suffix = 60;
    };

    subnets = {
      "untrusted" = {
        prefixId = "1";
        vlan = 1;
        nfrules_in = mkBefore [
          "iifname lan accept"
        ];
      };
      "lan" = {
        prefixId = "2";
        vlan = 2;
      };
      "server" = {
        prefixId = "c";
        vlan = 12;
        nfrules_in = mkBefore [
          "iifname lan accept"
        ];
      };
      "dmz" = {
        prefixId = "d";
        vlan = 13;
      };
      "management" = {
        prefixId = "f";
        vlan = 15;
      };
      "wan" = {
        prefixId = "0";
        vlan = 16;
        nfrules_in = mkBefore [
          "iifname != management accept"
        ];
      };
    };

    router.extraNfrules_in = [
      "iifname management accept"
      "iifname lan tcp dport 22 accept"
      # allow ssh from my old network
      "iifname wan ip6 saddr ***REMOVED_IPv6***::/60 tcp dport 22 accept"
    ];
  };

  schallernetz.servers.unbound.extraAuthZoneRecords =
    with config.schallernetz.networking.subnets; [
      "barebonej3160 in AAAA ${management.uniqueLocal.prefix}***REMOVED_IPv6***"
      "minisforumhm80 in AAAA ${server.uniqueLocal.prefix}***REMOVED_IPv6***"
    ];
}
