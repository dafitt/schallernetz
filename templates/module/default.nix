{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.MODULE;
in
{
  options.schallernetz.MODULE = with types; {
    enable = mkBoolOpt false "Enable MODULE.";
  };

  config = mkIf cfg.enable { };
}
