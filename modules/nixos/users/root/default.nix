{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.users.root;
in
{
  options.schallernetz.users.root = with types; {
    enable = mkBoolOpt false "Weather or not to enable additional configuration for the user 'root'";
  };

  config = mkIf cfg.enable {
    users.users."root" = {
      packages = with pkgs; [ ];

      openssh.authorizedKeys.keys = [
        # Put all allowed hosts' key here (user specific)
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
      ];
    };
  };
}
