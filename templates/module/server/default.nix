{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.MYSERVER;
in
{
  options.schallernetz.servers.MYSERVER = with types; {
    enable = mkBoolOpt false "Enable server MYSERVER.";
    name = mkOpt str "MYSERVER" "The name of the server.";
    ipv6Address = mkOpt str "" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start MYSERVER
    #$ sudo nixos-container root-login MYSERVER
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      #hostBridge = "br_lan";
      #localAddress = "192.168.178.x/24";
      localAddress6 = "${cfg.ipv6Address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}

# Dont forget to
# - add `schallernetz.servers.MYSERVER.enable = true;` to the hosts configuration!
# - add a DNS entry in case of a website!
