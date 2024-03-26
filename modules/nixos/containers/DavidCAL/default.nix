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

      config = { config, lib, pkgs, ... }: {

        imports = [ inputs.agenix.nixosModules.default ];

        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.secrets."DavidCAL-backup".file = ./DavidCAL-backup.age;
        age.secrets."DavidCAL-users" = { file = ./DavidCAL-users.age; owner = "radicale"; };

        environment.systemPackages = with pkgs; [ apacheHttpd ];

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
          paths = [ "${toString config.services.radicale.settings.storage.filesystem_folder}" ];

          encryption.mode = "repokey-blake2";
          encryption.passCommand = "cat ${config.age.secrets."DavidCAL-backup".path}";
          compression = "auto,zstd";
          prune.keep = {
            within = "1d"; # Keep all archives from the last day
            daily = 7;
            weekly = 4;
            monthly = -1; # Keep at least one archive for each month
          };
        };

        networking.firewall.interfaces."eth0" = {
          allowedTCPPorts = [ 5232 ];
          allowedUDPPorts = [ 5232 ];
        };

        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        networking.useHostResolvConf = mkForce false;

        system.stateVersion = "23.11";
      };
    };
  };
}
