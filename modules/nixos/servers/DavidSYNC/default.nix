{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.DavidSYNC;
in
{
  options.schallernetz.servers.DavidSYNC = with types; {
    enable = mkBoolOpt false "Enable server DavidSYNC.";
    name = mkOpt str "DavidSYNC" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":2b6" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start DavidSYNC
      #$ sudo nixos-container root-login DavidSYNC
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [ self.nixosModules."ntfy-systemd" ];

          environment.systemPackages = with pkgs; [
            ncdu
            tree
          ];

          services.syncthing = {
            # <https://nixos.wiki/wiki/Syncthing>
            enable = true;

            # Syncthing ports: 8384 for remote access to GUI
            # 22000 TCP and/or UDP for sync traffic
            # 21027/UDP for discovery
            # https://docs.syncthing.net/users/firewall.html
            openDefaultPorts = true;
            guiAddress = "[::]:8384"; # remote access

            overrideDevices = false; # whether to override devices, manually added or deleted through the WebUI
            overrideFolders = false; # whether to override folders, manually added or deleted through the WebUI

            settings = {
              # https://<ip/fqdn>:8384/rest/config with X-API-Key

              gui = {
                enabled = true;
                theme = "dark";
                user = "david";
                password = "***REMOVED_HASH***";
                useTLS = true;
              };

              options = {
                urAccepted = 3; # Anonymous Usage Reporting
              };

              defaults = {
                folder = {
                  minDiskFree = {
                    value = 5;
                    unit = "%";
                  };
                };
              };

              #folders = {
              #  "Default Folder" = {
              #    id = "default";
              #    path = config.services.syncthing.dataDir + "/Sync";
              #    #paused = false;
              #    #type = "sendreceive";
              #  };
              #  "home" = {
              #    path = config.services.syncthing.dataDir + "/home";
              #    #paused = false;
              #    #type = "sendreceive";
              #  };
              #};
            };
          };
          systemd.services.syncthing.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
          };

          networking = {
            enableIPv6 = true; # automatically get IPv6 and default route6
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 8384 ];
            };
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
              server _0 [${cfg.ip6Address}]:8384 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy.name}"
      ];
    }
  ];
}
