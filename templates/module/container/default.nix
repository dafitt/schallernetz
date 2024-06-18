{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.CONTAINERMODULE;
in
{
  options.schallernetz.containers.CONTAINERMODULE = with types; {
    enable = mkBoolOpt false "Enable container CONTAINERMODULE.";
    name = mkOpt str "CONTAINERMODULE" "The name of the container.";
    ipv6address = mkOpt str "" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start CONTAINERMODULE
    #$ sudo nixos-container root-login CONTAINERMODULE
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      #hostBridge = "br0";
      #localAddress = "192.168.178.x/24";
      localAddress6 = "${cfg.ipv6address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}

# Dont forget to add `schallernetz.containers.CONTAINERMODULE.enable = true;` to the hosts configuration!
