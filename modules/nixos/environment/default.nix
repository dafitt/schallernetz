{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.time;
in
{
  options.schallernetz.time = with types; {
    enable = mkBoolOpt true "Enable custom environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      micro
    ];
  };
}
