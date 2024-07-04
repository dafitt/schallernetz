{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.users.admin;
in
{
  options.schallernetz.users.admin = with types; {
    enable = mkBoolOpt true "Enable the user 'admin'.";
  };

  config = mkIf cfg.enable {
    users.users."admin" = {
      description = "Administrator";

      isNormalUser = true;

      extraGroups = [ "wheel" ];

      packages = with pkgs; [ ];

      openssh.authorizedKeys.keys = [
        # Put all ssh allowed users' key here
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
        "***REMOVED_SSH-PUBLICKEY*** david@DavidDESKTOP"
        "***REMOVED_SSH-PUBLICKEY*** david@DavidLEGION"
      ];
    };
  };
}
