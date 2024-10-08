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

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6Host = mkOpt str ":e" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6Host}" "Full IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    schallernetz.backups.paths = [
      "/var/lib/nixos-containers/${cfg.name}/etc/group"
      "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
      "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
      "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
      "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.forgejo.stateDir}"
    ];

    age.secrets."ACME_DODE" = { file = ../ACME_DODE.age; };

    #$ sudo nixos-container start forgejo
    #$ sudo nixos-container root-login forgejo
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = cfg.subnet;
      localAddress6 = "${cfg.ip6Address}/64";

      bindMounts.${config.age.secrets."ACME_DODE".path}.isReadOnly = true;

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        imports = with inputs;[ self.nixosModules."ntfy-systemd" ];

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
        systemd.services.forgejo.unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
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
          certs."${cfg.name}.${hostConfig.networking.domain}" = {
            extraDomainNames = [ "${cfg.name}.lan.${hostConfig.networking.domain}" ];
            dnsProvider = "dode";
            dnsResolver = "ns1.domainoffensive.de";
            environmentFile = hostConfig.age.secrets."ACME_DODE".path;

            group = "nginx";
          };
        };
        systemd.services."acme-${cfg.name}.${hostConfig.networking.domain}".unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        services.nginx = {
          enable = true;
          recommendedTlsSettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;
          recommendedProxySettings = true;
          clientMaxBodySize = "10G";

          virtualHosts."${cfg.name}.${hostConfig.networking.domain}" = {
            forceSSL = true;
            useACMEHost = "${cfg.name}.${hostConfig.networking.domain}"; # DNS-01 challenge
            extraConfig = ''add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;'';

            # to localhost
            locations."/".proxyPass = "http://[${config.services.forgejo.settings.server.HTTP_ADDR}]:${toString config.services.forgejo.settings.server.HTTP_PORT}";
          };
        };

        networking = {
          # for acme
          enableIPv6 = true; # automatically get IPv6 and default route6
          useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686
          nameservers = [ hostConfig.schallernetz.servers.unbound.ip6Address ];

          firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 443 ];
          };
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
