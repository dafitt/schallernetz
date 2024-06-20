{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.security.certificateFiles;
in
{
  options.schallernetz.security.certificateFiles = with types;{
    enable = mkBoolOpt true "Whether or not to import provided certificate files.";
  };

  config = mkIf cfg.enable {
    security.pki.certificateFiles = [
      ./***REMOVED_DOMAIN***.pem
    ];
  };
}
