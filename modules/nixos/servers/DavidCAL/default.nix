{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.DavidCAL;
in
{
  options.schallernetz.servers.DavidCAL = with types; {
    enable = mkBoolOpt false "Enable server DavidCAL.";
    name = mkOpt str "DavidCAL" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":297" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start DavidCAL
      #$ sudo nixos-container root-login DavidCAL
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

          # agenix secrets
          age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          age.secrets."DavidCAL-backup" = { file = ./DavidCAL-backup.age; };
          age.secrets."DavidCAL-users" = { file = ./DavidCAL-users.age; owner = "radicale"; };

          environment.systemPackages = with pkgs; [ apacheHttpd nfs-utils ];

          # [Radicale Documentation](https://radicale.org/v3.html#basic-configuration)
          services.radicale = {
            enable = true;

            settings = {
              auth = {
                # plain "USER:PASSWORD"
                # bcrypt #$ htpasswd -BC7 -c /var/lib/radicale/users <user>
                #$ nix shell nixpkgs#apacheHttpd
                type = "htpasswd";
                htpasswd_filename = config.age.secrets."DavidCAL-users".path;
                htpasswd_encryption = "plain";
              };
              server = {
                hosts = [ "[::]:5232" ];
                # TODO ssl
                #ssl = true;
                #certificate = "/path/to/server_cert.pem";
                #key = "/path/to/server_key.pem";
                #certificate_authority = "/path/to/client_cert.pem";
              };
              storage = {
                filesystem_folder = "/var/lib/radicale/collections";
                hook = ''${pkgs.git}/bin/git add -A && (${pkgs.git}/bin/git diff --cached --quiet || ${pkgs.git}/bin/git commit -m "Changes by "%(user)s)'';
              };
            };
          };
          systemd.services.radicale.preStart =
            let cfg = config.services.radicale.settings; in
            # Initialize Git
            ''
              if [ ! -d ${toString cfg.storage.filesystem_folder}/.git ]; then
                cd ${toString cfg.storage.filesystem_folder}
                ${pkgs.git}/bin/git init
                ${pkgs.git}/bin/git config user.email ""
                ${pkgs.git}/bin/git config user.name "radicale-git"
                if [ ! -e .gitignore ]; then
                  echo -e ".Radicale.cache\n.Radicale.lock\n.Radicale.tmp-*" > .gitignore
                fi
              fi
            '';
          systemd.services.radicale.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
          };

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 5232 ];
            allowedUDPPorts = [ 5232 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };

      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}${toString config.containers.${cfg.name}.config.services.radicale.settings.storage.filesystem_folder}"
      ];
    })
    {
      schallernetz.servers.haproxy-server = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:5232 maxconn 32 check
          ''
        ];
      };
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        # Don't allow access to connection between server and main reverse proxy from other subnets.
        "ip6 daddr ${cfg.ip6Address} tcp dport 5232 drop"
        "ip6 daddr ${cfg.ip6Address} udp dport 5232 drop"
      ];
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy-server.name}"
      ];
    }
  ];
}
