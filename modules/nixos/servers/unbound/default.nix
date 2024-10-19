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

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":9" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";

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
          imports = with inputs; [ self.nixosModules."ntfy-systemd" ];

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

              auth-zone = [{
                name = "lan.${hostConfig.networking.domain}";
                zonefile = "${pkgs.writeText "lan.${hostConfig.networking.domain}.zone" ''
                $ORIGIN lan.${hostConfig.networking.domain}.
                $TTL 6h

                @ IN SOA ${cfg.name} admin.***REMOVED_DOMAIN***. (
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
          systemd.services.unbound.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
          };

          networking = {
            enableIPv6 = true; # automatically get IP6 and default route6
            interfaces."eth0".tempAddress = "default"; # IPv6 temporary address (aka privacy extensions)
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 53 ];
              allowedUDPPorts = [ 53 ];
            };
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        # Allow access to dns from all other subnets.
        "ip6 daddr ${cfg.ip6Address} udp dport 53 limit rate 70/second accept"
      ];
    }
  ];
}
