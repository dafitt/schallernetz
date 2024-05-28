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
      isNormalUser = true;
      description = "Administrator";

      extraGroups = [ "wheel" ];

      packages = with pkgs; [ ];

      openssh.authorizedKeys.keys = [
        # Put all allowed hosts' key here (user specific)
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
      ];
    };
  };
}
