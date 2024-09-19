{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.forgejo;
in
{
  options.schallernetz.containers.forgejo = with types; {
    enable = mkBoolOpt false "Enable container forgejo.";
    name = mkOpt str "forgejo" "The name of the container.";
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

      #$ sudo nixos-container start forgejo
      #$ sudo nixos-container root-login forgejo
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress6 = "${cfg.ipv6Address}/64";

        bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # mount host's ssh key for agenix secrets in the container

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          # agenix secrets
          imports = with inputs; [ agenix.nixosModules.default ];
          age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

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

          age.secrets."acme_dode" = { file = ../haproxy/acme_dode.age; };
          security.acme = {
            defaults.email = "admin@***REMOVED_DOMAIN***";
            acceptTerms = true;

            # DNS-01 challenge
            certs."${config.services.forgejo.settings.server.DOMAIN}" = {
              dnsProvider = "dode";
              environmentFile = config.age.secrets."acme_dode".path;
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
            nameservers = [ hostConfig.schallernetz.containers.unbound.ipv6Address ];

            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 22 443 ];
            };
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
  ];
}
