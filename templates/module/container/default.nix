{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.CONTAINERMODULE;
in
{
  options.schallernetz.containers.CONTAINERMODULE = with types; {
    enable = mkBoolOpt false "Enable container CONTAINERMODULE";
    name = mkOpt str "CONTAINERMODULE" "The name of the container";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start CONTAINERMODULE
    #$ sudo nixos-container root-login CONTAINERMODULE
    containers.${cfg.name} = {

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
