{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.users.rebuild;
in
{
  options.schallernetz.users.rebuild = with types; {
    enable = mkBoolOpt true "Enable the user 'rebuild', for remote rebuilding.";
  };

  config = mkIf cfg.enable {
    users.groups."rebuild" = { };
    users.users."rebuild" = {
      description = "rebuild-only user";

      isSystemUser = true;
      group = "rebuild";
      shell = pkgs.bashInteractive;

      extraGroups = [ "wheel" ];

      openssh.authorizedKeys.keys = [
        # Put all ssh allowed users' key here
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
        "***REMOVED_SSH-PUBLICKEY*** root@DavidDESKTOP"
        "***REMOVED_SSH-PUBLICKEY*** david@DavidDESKTOP"
        "***REMOVED_SSH-PUBLICKEY*** root@DavidLEGION"
        "***REMOVED_SSH-PUBLICKEY*** david@DavidLEGION"
      ];
    };

    nix.settings.trusted-users = [ "rebuild" ];

    security.sudo.extraRules = [{
      users = [ "rebuild" ];
      commands = [{ command = "ALL"; options = [ "SETENV" "NOPASSWD" ]; }];
    }];
  };
}
