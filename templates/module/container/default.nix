{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.containermodule;
in
{
  options.schallernetz.containers.containermodule = with types; {
    enable = mkBoolOpt false "Enable container containermodule";
    name = mkOpt str "containermodule" "The name of the container";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start containermodule
    #$ sudo nixos-container root-login containermodule
    containers.${cfg.name} = { };
  };
}
