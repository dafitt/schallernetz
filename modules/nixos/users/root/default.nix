{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.users.root;
in
{
  options.schallernetz.users.root = with types; {
    enable = mkBoolOpt true "Whether or not to enable additional configuration for the user 'root'.";
    allowSshPasswordAuthentication = mkBoolOpt false "Whether or not to allow ssh login with a password.";
  };

  config = mkIf cfg.enable {
    users.users."root" = {
      packages = with pkgs; [ ];

      openssh.authorizedKeys.keys = [
        # Put all ssh allowed users' key here
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
      ];
    };

    services.openssh.settings = mkIf cfg.allowSshPasswordAuthentication {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
    };
  };
}
