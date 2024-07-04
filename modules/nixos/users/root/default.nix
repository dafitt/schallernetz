{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.users.root;
in
{
  options.schallernetz.users.root = with types; {
    enable = mkBoolOpt false "Whether or not to enable additional configuration for the user 'root'.";
  };

  config = mkIf cfg.enable {
    users.users."root" = {
      packages = with pkgs; [ ];

      openssh.authorizedKeys.keys = [
        # Put all ssh allowed users' key here
        # "ssh-ed25519 AAAAC3Nxxxxx user@host"
      ];
    };

    services.openssh.settings = {
      PermitRootLogin = "yes";

      # require public key authentication for better security
      #PasswordAuthentication = false;
      #KbdInteractiveAuthentication = false;
      #PermitRootLogin = "no";
    };
  };
}
