{
  #$ sudo nixos-container start DavidSYNC
  #$ sudo nixos-container root-login DavidSYNC

  containers."DavidSYNC" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";

    config = { config, lib, ... }: {

      services.syncthing = {
        # <https://nixos.wiki/wiki/Syncthing>
        enable = true;

        openDefaultPorts = true;
        guiAddress = "0.0.0.***REMOVED_IPv6***"; # remote access

        #overrideDevices = false; # whether to override devices manually added or deleted through the WebUI
        #overrideFolders = false; # whether to override folders manually added or deleted through the WebUI

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

          devices = {
            "DavidDESKTOP" = {
              id = "***REMOVED_SYNCTHING-ID***";
              compression = "never";
            };
            "DavidLEGION" = {
              id = "***REMOVED_SYNCTHING-ID***";
              compression = "always";
            };
            "DavidTUX" = {
              id = "***REMOVED_SYNCTHING-ID***";
              compression = "always";
            };
            "DavidPIXEL" = {
              id = "***REMOVED_SYNCTHING-ID***";
              compression = "always";
            };
          };

          defaults = {
            folder = {
              # initial extra care
              paused = true;
              type = "receiveonly";

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
              devices = [ "DavidDESKTOP" "DavidLEGION" "DavidTUX" "DavidPIXEL" ];
              #paused = false;
              #type = "sendreceive";
            };
            "home" = {
              path = config.services.syncthing.dataDir + "/home";
              devices = [ "DavidDESKTOP" "DavidLEGION" "DavidTUX" ];
              #paused = false;
              #type = "sendreceive";
            };
          };
        };
      };

      networking.firewall.interfaces."eth0" = {
        allowedTCPPorts = [ 8080 ];
      };

      # Use systemd-resolved inside the container
      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;
      #services.resolved.enable = true;

      system.stateVersion = "23.11";
    };
  };
}
