{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.DavidSYNC;
in
{
  options.schallernetz.containers.DavidSYNC = with types; {
    enable = mkBoolOpt false "Enable container DavidSYNC.";
    name = mkOpt str "DavidSYNC" "The name of the container.";
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start DavidSYNC
      #$ sudo nixos-container root-login DavidSYNC
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress6 = "${cfg.ipv6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          services.syncthing = {
            # <https://nixos.wiki/wiki/Syncthing>
            enable = true;

            openDefaultPorts = true;
            guiAddress = "[::]:8384"; # remote access

            overrideDevices = false; # whether to override devices, manually added or deleted through the WebUI
            #overrideFolders = false; # whether to override folders, manually added or deleted through the WebUI

            settings = {
              # https://192.168.19.***REMOVED_IPv6***/rest/config with X-API-Key

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

              folders = {
                "Default Folder" = {
                  id = "default";
                  path = config.services.syncthing.dataDir + "/Sync";
                  #paused = false;
                  #type = "sendreceive";
                };
                "home" = {
                  path = config.services.syncthing.dataDir + "/home";
                  #paused = false;
                  #type = "sendreceive";
                };
              };
            };
          };

          networking = {
            enableIPv6 = true; # # automatically get IPv6 and default route6
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
      schallernetz.containers.haproxy = {
        frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ipv6Address}]:8384 maxconn 32 check
          ''
        ];
      };
    }
  ];
}
