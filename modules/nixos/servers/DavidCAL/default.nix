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
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}${toString config.containers.${cfg.name}.config.services.radicale.settings.storage.filesystem_folder}"
      ];

      #$ sudo nixos-container start DavidCAL
      #$ sudo nixos-container root-login DavidCAL
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

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 5232 ];
            allowedUDPPorts = [ 5232 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      # entry in main reverse proxy
      schallernetz.servers.haproxy = {
        frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ipv6Address}]:5232 maxconn 32 check
          ''
        ];
      };
    }
  ];
}
