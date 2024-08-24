{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.gitea;
in
{
  options.schallernetz.containers.gitea = with types; {
    enable = mkBoolOpt false "Enable container gitea.";
    name = mkOpt str "gitea" "The name of the container.";
    ipv6address = mkOpt str "***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.gitea.stateDir}"
      ];

      #$ sudo nixos-container start gitea
      #$ sudo nixos-container root-login gitea
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress6 = "${cfg.ipv6address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          services.gitea = {
            enable = true;
            appName = "SchallerGit";

            settings = {
              server = {
                DOMAIN = "${cfg.name}.${hostConfig.networking.domain}";
                HTTP_PORT = 3000;

                DISABLE_SSH = true;
              };
            };
          };

          networking = {
            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 3000 ];
            };
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      # entry in main reverse proxy
      schallernetz.services.haproxy.frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
      services.haproxy.config = mkAfter ''
        backend ${cfg.name}
          mode http
          server _0 [${cfg.ipv6address}]:3000 maxconn 32 check
      '';
    }
  ];
}
