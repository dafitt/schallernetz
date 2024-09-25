{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.haproxy;
in
{
  options.schallernetz.servers.haproxy = with types; {
    enable = mkBoolOpt false "Enable server haproxy.";
    name = mkOpt str "haproxy" "The name of the server.";
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";

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

  config = mkIf cfg.enable {
    #$ sudo nixos-container start unbound
    #$ sudo nixos-container root-login unbound
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br_lan";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "${cfg.ipv6Address}/64";

      bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # mount host's ssh key for agenix secrets in the container

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        imports = with inputs; [
          agenix.nixosModules.default
          self.nixosModules."ntfy-systemd"
        ];

        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

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
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        age.secrets."ACME_DODE" = { file = ../ACME_DODE.age; };
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
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        networking = {
          # for acme
          enableIPv6 = true; # automatically get IPv6 and default route6
          useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686
          nameservers = [ hostConfig.schallernetz.servers.unbound.ipv6Address ];

          firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 80 443 ];
          };
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
