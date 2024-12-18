# import this module with
#` imports = [ inputs.self.nixosModules."systemd/ntfy" ];

{ config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.systemd.ntfy;
in
{
  options.schallernetz.systemd.ntfy = with types; {
    enable = mkBoolOpt true "Whether or not to provide systemd units ['ntfy-failure@' 'ntfy-success@']";
    url = mkOption {
      type = str;
      default = "https://ntfy.lan.***REMOVED_DOMAIN***";
      description = "URL to the ntfy server.";
      example = "https://ntfy.sh";
    };
    topic = mkOpt str "administration" "The topic to publish the notifications to.";
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
            --title "[%H] %i.service failed" \
            --priority 4 \
            --tags red_circle \
            ${cfg.url}/${cfg.topic} \
            "$(${pkgs.systemd}/bin/journalctl --unit %i --lines 5 --reverse --no-pager --boot | ${pkgs.coreutils}/bin/head -c 4096)"'
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
              ${cfg.url}/${cfg.topic} \
              "[%H] %i.service succeeded"
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
