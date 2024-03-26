{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.module;
in
{
  options.schallernetz.module = with types; {
    enable = mkBoolOpt false "Enable the user 'admin'";
  };

  config = mkIf cfg.enable {
    users.users."admin" = {
      isNormalUser = true;
      description = "Administrator";

      extraGroups = [ "wheel" ];

      packages = with pkgs; [ ];
    };
  };
}
