{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.haproxy-dmz;
in
{
  options.schallernetz.servers.haproxy-dmz = with types; {
    enable = mkBoolOpt false "Enable server haproxy-dmz.";
    name = mkOpt str "haproxy-dmz" "The name of the server.";

    subnet = mkOpt str "dmz" "The name of the subnet which the server should be part of.";
    ip6HostAddress = mkOpt str ":7fd" "The ipv6's host part for the server.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the server.";

    frontends.extraConfig = mkOpt (listOf str) [ ] "List of additional frontends (config).";
    frontends.www.extraConfig = mkOption {
      type = listOf str;
      default = [ ];
      description = mdDoc ''
        List of strings containing additional configuration for the frontend www.
        Intended for additional backends: `"use_backend <backend> if { req.hdr(host) -i <domain> }"`.
      '';
    };

    backends.extraConfig = mkOpt (listOf str) [ ] "List of additional backends (config).";
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

        bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # mount host's ssh key for agenix secrets in the container

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [
            agenix.nixosModules.default
            self.nixosModules."ntfy-systemd"
          ];

          age = {
            identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."ACME_DODE" = { file = ../ACME_DODE.age; };
            secrets."DDNS-K57174-51715" = {
              file = ../DDNS-K57174-51715.age;
              owner = config.services.inadyn.user;
              group = config.services.inadyn.group;
            };
          };

          # Reverse Proxy before the application servers
          # [HAProxy config tutorials](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/core-concepts/overview/)
          # [Essential Configuration](https://www.haproxy.com/blog/the-four-essential-sections-of-an-haproxy-configuration)
          services.haproxy = {
            enable = true;
            config = ''
              global
                daemon
                maxconn 5000
                ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

              defaults
                timeout connect 10s
                timeout client 30s
                timeout server 30s

              ${concatStringsSep "\n" cfg.frontends.extraConfig}

              frontend www
                mode http
                bind [::]:80 v4v6
                http-request redirect scheme https unless { ssl_fc }
                bind [::]:443 v4v6 ssl crt /var/lib/acme/***REMOVED_DOMAIN***/full.pem

                # HSTS (HTTPS-Strict-Transport-Security) against man-in-the-middle attacks
                http-response set-header Strict-Transport-Security "max-age=16000000; includeSubDomains; preload;"

                ${concatStringsSep "\n  " cfg.frontends.www.extraConfig}

              ${concatStringsSep "\n" cfg.backends.extraConfig}
            '';
          };
          systemd.services.haproxy.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
          };

          # https://wiki.nixos.org/wiki/ACME
          security.acme = {
            acceptTerms = true;
            defaults.email = "admin@***REMOVED_DOMAIN***";

            certs."***REMOVED_DOMAIN***" = {
              extraDomainNames = [ "*.***REMOVED_DOMAIN***" "*.lan.***REMOVED_DOMAIN***" ];
              dnsProvider = "dode";
              dnsResolver = "ns1.domainoffensive.de";
              environmentFile = config.age.secrets."ACME_DODE".path;

              group = config.services.haproxy.group;
            };
          };
          systemd.services."acme-***REMOVED_DOMAIN***".unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              networkConfig.DNS = [ hostConfig.schallernetz.servers.unbound.ip6Address ];
              ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 80 443 ];
          };

          # DDNS: tell my domain my dynamic ipv6
          services.inadyn = {
            enable = true;

            interval = "*-*-* *:0/***REMOVED_IPv6***";
            logLevel = "info";
            settings = {
              allow-ipv6 = true;
              custom."do.de" = {
                username = "DDNS-K57174-51715";
                include = config.age.secrets."DDNS-K57174-51715".path; #`password = `
                hostname = "lan.wireguard.***REMOVED_DOMAIN***";
                ddns-server = "ddns.do.de";
                ddns-path = "/?myip=%i";
                checkip-command = "${pkgs.iproute2}/bin/ip -6 addr show dev eth0 scope global -temporary | ${pkgs.gnugrep}/bin/grep -G 'inet6 [2-3]' "; # get the non-temporary global unicast address
              };
            };
          };
          systemd.services.inadyn.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} tcp dport { 80, 443 } accept"
      ];
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN AAAA ${cfg.ip6Address}"
      ];
    }
  ];
}
