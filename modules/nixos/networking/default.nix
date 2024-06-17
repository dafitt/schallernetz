{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.networking;
in
{
  options.schallernetz.networking = with types; {
    enable = mkBoolOpt true "Enable network configuration.";
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = host;
      domain = "***REMOVED_DOMAIN***";
    };
  };
}
