{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.module;
in
{
  options.schallernetz.module = with types; {
    enable = mkBoolOpt false "Enable module";
  };

  config = mkIf cfg.enable { };
}
