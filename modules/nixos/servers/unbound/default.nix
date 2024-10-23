{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.unbound;
in
{
  options.schallernetz.servers.unbound = with types; {
    enable = mkBoolOpt false "Enable server unbound.";
    name = mkOpt str "unbound" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the server should be part of.";
    ip6HostAddress = mkOpt str ":9" "The ipv6's host part for the server.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the server.";

    extraAuthZoneRecords = mkOption {
      type = listOf str;
      default = [ ];
      description = "A list of dns records to add to the authoritative zone.";
      example = [
        "example IN AAAA ***REMOVED_IPv6***"
        "${cfg.name} IN AAAA ${cfg.ip6Address}"
      ];
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start unbound
      #$ sudo nixos-container root-login unbound
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          environment.systemPackages = with pkgs; [ dig ];

          # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
          services.unbound = {
            enable = true;

            # https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html
            settings = {
              server = {
                # the interface ip's that is used to connect to the network
                interface = [ "${cfg.ip6Address}" "***REMOVED_IPv6***" ];
                access-control = [ "${hostConfig.schallernetz.networking.uniqueLocal.prefix}::/56 allow" ];

                module-config = "'dns64 validator iterator'";

                # recommended privacy settings
                qname-minimisation = true;
                harden-glue = true;
                harden-dnssec-stripped = true;
                use-caps-for-id = false;
                prefetch = true;
                edns-buffer-size = 1232;
                hide-identity = true;
                hide-version = true;
              };

              auth-zone = [rec {
                name = "lan.${hostConfig.schallernetz.networking.domain}";
                zonefile = "${pkgs.writeText "${name}.zone" ''
                  $ORIGIN ${name}.
                  $TTL 6h

                  @ IN SOA ${cfg.name} admin.${hostConfig.schallernetz.networking.domain}. (
                    2024092301 ; serial number YYMMDDNN
                    12h        ; refresh
                    2h         ; update retry
                    1w         ; expire
                    2h         ; minimum TTL
                  )
                  @ IN NS ${cfg.name}
                  ${cfg.name} IN AAAA ${cfg.ip6Address}

                  ${concatStringsSep "\n" cfg.extraAuthZoneRecords}
                ''}";
              }];

              forward-zone = [{
                name = ".";
                forward-addr = [
                  "***REMOVED_IPv6***#dns.quad9.net"
                  "***REMOVED_IPv6***#dns.quad9.net"
                ];
                forward-tls-upstream = true;
              }];
            };
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              networkConfig.DNS = [ "***REMOVED_IPv6***" ];
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 53 ];
            allowedUDPPorts = [ 53 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "iifname != wan ip6 daddr ${cfg.ip6Address} udp dport 53 accept" # Allow access to dns from all other subnets.
      ];
      schallernetz.networking.subnets."wan".nfrules_in = [
        "iifname ${cfg.subnet} ip6 saddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} accept" # Allow access to internet.
      ];
    }
  ];
}
