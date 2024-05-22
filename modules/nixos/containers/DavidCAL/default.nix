{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.DavidCAL;
in
{
  options.schallernetz.containers.DavidCAL = with types; {
    enable = mkBoolOpt false "Enable container DavidCAL";
    name = mkOpt str "DavidCAL" "The name of the container";

    remoteBackups = mkBoolOpt true "Whether or not to enable remote backups";
  };

  config = mkIf cfg.enable {

    schallernetz.services.haproxy.frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
    services.haproxy.config = mkAfter ''
      backend ${cfg.name}
        server _0 [***REMOVED_IPv6***]:5232 maxconn 32 check
    '';

    #$ sudo nixos-container start DavidCAL
    #$ sudo nixos-container root-login DavidCAL
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "***REMOVED_IPv6***/56";

      bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {

        imports = [ inputs.agenix.nixosModules.default ];

        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.secrets."DavidCAL-backup".file = ./DavidCAL-backup.age;
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
        systemd.services."radicale".preStart =
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

        # Backup radicale data
        services.borgbackup.jobs."localBackup" = {
          repo = "/borgbackup";
          encryption.mode = "repokey-blake2";
          encryption.passCommand = "cat ${config.age.secrets."DavidCAL-backup".path}";
          compression = "auto,zstd";

          paths = [ "${toString config.services.radicale.settings.storage.filesystem_folder}" ];
          startAt = "daily";
          prune.keep = {
            within = "1d"; # everything
            daily = 7;
            weekly = 4;
            monthly = -1; # - means at least
          };
        };


        services.rpcbind.enable = mkIf cfg.remoteBackups true; # needed for NFS
        systemd.mounts = mkIf cfg.remoteBackups [{
          type = "nfs";
          mountConfig = {
            Options = "noatime";
          };
          what = "***REMOVED_IPv4***:/SchallernetzBACKUP";
          where = "/mnt/SchallernetzBACKUP_NAS4";
          partOf = [ "borgbackup-job-SchallernetzBACKUP.service" ];
        }];
        systemd.services."borgbackup-job-SchallernetzBACKUP" = mkIf cfg.remoteBackups {
          after = [ "mnt-SchallernetzBACKUP_NAS4.mount" ];
          requires = [ "mnt-SchallernetzBACKUP_NAS4.mount" ];
        };
        services.borgbackup.jobs."SchallernetzBACKUP" = mkIf cfg.remoteBackups {
          repo = "/mnt/SchallernetzBACKUP_NAS4/DavidCAL";
          removableDevice = true;
          encryption.mode = "repokey-blake2";
          encryption.passCommand = "cat ${config.age.secrets."DavidCAL-backup".path}";
          compression = "auto,zstd";

          paths = [ "${toString config.services.radicale.settings.storage.filesystem_folder}" ];
          preHook = "mkdir -p /mnt/SchallernetzBACKUP_NAS4/DavidCAL";
          startAt = "Mon *-*-* ***REMOVED_IPv6***";
          prune.keep = {
            within = "1w"; # everything
            daily = 7;
            weekly = 4;
            monthly = -1; # - means at least
          };
        };

        networking.firewall.interfaces."eth0" = {
          allowedTCPPorts = [ 5232 ];
          allowedUDPPorts = [ 5232 ];
        };

        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        networking.useHostResolvConf = mkForce false;

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
