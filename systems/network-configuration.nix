{ lib, ... }: with lib; {
  schallernetz.networking = {
    enable = true;
    domain = "***REMOVED_DOMAIN***";

    uniqueLocal = rec {
      prefix_ = "***REMOVED_IPv6***";
      prefix = "${prefix_}0";
      suffix = 60;
    };

    router.nfrules_in = [
      "iifname management accept"
      "iifname lan tcp dport 22 accept"
      "iifname wan ip6 saddr ***REMOVED_IPv6***::/60 tcp dport 22 accept"
    ];

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
  };
}
