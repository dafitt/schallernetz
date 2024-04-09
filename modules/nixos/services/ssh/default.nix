{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.services.ssh;
in
{
  options.schallernetz.services.ssh = with types; {
    enable = mkBoolOpt true "Enable ssh (access)";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";

        # require public key authentication for better security
        #PasswordAuthentication = false;
        #KbdInteractiveAuthentication = false;
        #PermitRootLogin = "no";
      };
    };
  };
}
