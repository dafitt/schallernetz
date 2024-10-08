{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.shells;
  enabledSubModules = filter (n: cfg.${n}.enable or false) (attrNames cfg);
in
{
  options.schallernetz.shells = with types; {
    default = mkOpt (nullOr (enum [ "bash" "fish" ])) "fish" "Which default shell to set.";
  };
}
