{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.bitwarden;
in
{
  options.schallernetz.containers.bitwarden = with types; {
    enable = mkBoolOpt false "Enable container bitwarden.";
    name = mkOpt str "bitwarden" "The name of the container.";
    ipv6address = mkOpt str "***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}/var/lib/bitwarden_rs" #TODO 24.11 /var/lib/vaultwarden
        "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.vaultwarden.backupDir}"
      ];

      #$ sudo nixos-container start bitwarden
      #$ sudo nixos-container root-login bitwarden
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress6 = "${cfg.ipv6address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          services.vaultwarden = {
            enable = true;
            backupDir = "/var/backup/vaultwarden";

            config = {
              DOMAIN = "https://${cfg.name}.${hostConfig.networking.domain}";
              ROCKET_ADDRESS = "***REMOVED_IPv4***";
              ROCKET_PORT = 8222;
            };
          };

          # Local reverse proxy for IPv6
          # TODO security: https & secret_key
          services.haproxy = {
            enable = true;
            config = ''
              global
                daemon

              defaults
                mode http
                timeout connect 5s
                timeout client 50s
                timeout server 50s

              frontend vaultwarden
                bind [::]:80 v4v6
                default_backend vaultwarden

              backend vaultwarden
                server vaultwarden 127.0.0.***REMOVED_IPv6*** maxconn 32 check
            '';
          };

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 80 ];
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
          server _0 [${cfg.ipv6address}]:80 maxconn 32 check
      '';
    }
  ];
}
