{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.ssh;
in
{
  options.schallernetz.ssh = with types; {
    enable = mkBoolOpt true "Enable ssh (access).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      startWhenNeeded = true;

      settings = {
        # require public key authentication for better security
        PasswordAuthentication = mkDefault false;
        KbdInteractiveAuthentication = mkDefault false;
      };
    };
  };
}
