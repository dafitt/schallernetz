{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.forgejo;
in
{
  options.schallernetz.servers.forgejo = with types; {
    enable = mkBoolOpt false "Enable server forgejo.";
    name = mkOpt str "forgejo" "The name of the server.";
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.forgejo.stateDir}"
      ];

      age.secrets."acme_dode" = { file = ../haproxy/acme_dode.age; };

      #$ sudo nixos-container start forgejo
      #$ sudo nixos-container root-login forgejo
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress6 = "${cfg.ipv6Address}/64";

        bindMounts.${config.age.secrets."acme_dode".path}.isReadOnly = true;

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          services.forgejo = {
            enable = true;

            settings = {
              server = {
                DOMAIN = "${cfg.name}.${hostConfig.networking.domain}";
                ROOT_URL = "https://${config.services.forgejo.settings.server.DOMAIN}/";
                HTTP_ADDR = "***REMOVED_IPv6***"; # listen address
              };
              session.COOKIE_SECURE = true; # We're assuming SSL-only connectivity
            };
          };

          services.openssh = {
            enable = true;
            allowSFTP = false;
            startWhenNeeded = true;

            settings = {
              #GatewayPorts = "yes";
              PermitRootLogin = "no";
              PasswordAuthentication = false;
            };
          };

          security.acme = {
            defaults.email = "admin@***REMOVED_DOMAIN***";
            acceptTerms = true;

            # DNS-01 challenge
            certs."${config.services.forgejo.settings.server.DOMAIN}" = {
              dnsProvider = "dode";
              environmentFile = hostConfig.age.secrets."acme_dode".path;
              dnsResolver = "ns1.domainoffensive.de";

              #extraDomainNames = [ "forgejo.***REMOVED_DOMAIN***" ];
              group = "nginx";
            };
          };

          services.nginx = {
            enable = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;
            recommendedProxySettings = true;
            clientMaxBodySize = "10G";

            virtualHosts."${config.services.forgejo.settings.server.DOMAIN}" = {
              forceSSL = true;
              useACMEHost = "${config.services.forgejo.settings.server.DOMAIN}"; # DNS-01 challenge
              extraConfig = ''add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;'';

              # to localhost
              locations."/".proxyPass = "http://[${config.services.forgejo.settings.server.HTTP_ADDR}]:${toString config.services.forgejo.settings.server.HTTP_PORT}";
            };
          };

          networking = {
            # for acme
            enableIPv6 = true; # automatically get IPv6 and default route6
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686
            nameservers = [ hostConfig.schallernetz.servers.unbound.ipv6Address ];

            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 443 ];
            };
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
  ];
}
