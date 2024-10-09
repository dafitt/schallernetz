{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.bitwarden;
in
{
  options.schallernetz.servers.bitwarden = with types; {
    enable = mkBoolOpt false "Enable server bitwarden.";
    name = mkOpt str "bitwarden" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6Host = mkOpt str ":b" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6Host}" "Full IPv6 address of the container.";
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
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [ self.nixosModules."ntfy-systemd" ];

          services.vaultwarden = {
            enable = true;
            backupDir = "/var/backup/vaultwarden";

            config = {
              DOMAIN = "https://${cfg.name}.${hostConfig.networking.domain}";
              ROCKET_ADDRESS = "***REMOVED_IPv4***";
              ROCKET_PORT = 8222;
            };
          };
          systemd.services.vaultwarden.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
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
      schallernetz.servers.haproxy = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }"
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:80 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy.name}"
      ];
    }
  ];
}
