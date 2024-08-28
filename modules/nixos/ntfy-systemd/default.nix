# import this module with
#` imports = [ inputs.self.nixosModules."ntfy-systemd" ];

{ config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.ntfy-systemd;
in
{
  options.schallernetz.ntfy-systemd = with types; {
    enable = mkBoolOpt true "Whether or not to provide systemd units ['ntfy-failure@' 'ntfy-success@']";
    url = mkOption {
      type = str;
      default = "https://ntfy.***REMOVED_DOMAIN***";
      description = "URL to the ntfy server.";
      example = "https://ntfy.sh";
    };
  };

  config = {
    systemd.services = {
      "ntfy-failure@" = {
        unitConfig = {
          Description = "send a notification with 'OnFailure=ntfy-failure@%i.service' of another systemd service";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.bash}/bin/bash -c ' \
          ${pkgs.ntfy-sh}/bin/ntfy publish \
            --title "[%u] %i.service failed" \
            --priority 5 \
            --tags red_circle \
            ${cfg.url}/%H \
            "$(${pkgs.systemd}/bin/journalctl --unit %i --lines 10 --reverse --no-pager --boot | ${pkgs.coreutils}/bin/head -c 4096)"'
        '';
        };
      };
      "ntfy-success@" = {
        unitConfig = {
          Description = "send a notification with 'OnSuccess=ntfy-success@%i.service' of another systemd service";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.ntfy-sh}/bin/ntfy publish \
              --priority 2 \
              --tags green_circle \
              ${cfg.url}/%H \
              "[%u] %i.service succeeded"
          '';
        };
      };
      "ntfy-usage" = {
        unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/false";
        };
      };
    };
  };
}
