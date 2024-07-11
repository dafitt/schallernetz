{ config, pkgs, ... }:

{
  config = {
    security.pki.certificateFiles = [ ./***REMOVED_DOMAIN***.pem ];

    systemd.services."ntfy-systemd-failure@" = {
      unitConfig = {
        Description = "send a notification with 'OnFailure=ntfy-systemd-failure@%i.service' of another systemd service";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.bash}/bin/bash -c ' \
          ${pkgs.ntfy-sh}/bin/ntfy publish \
            --title "[%u] %i.service failed" \
            --tags red_circle \
            ntfy.${config.networking.domain}/%H \
            "$(${pkgs.systemd}/bin/journalctl --unit %i --lines 5 --reverse --no-pager --boot | ${pkgs.coreutils}/bin/head -c 4096)"'
        '';
      };
    };
    systemd.services."ntfy-systemd-success@" = {
      unitConfig = {
        Description = "send a notification with 'OnSuccess=ntfy-systemd-success@%i.service' of another systemd service";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.ntfy-sh}/bin/ntfy publish \
            --tags green_circle \
            ntfy.${config.networking.domain}/%H \
            "[%u] %i.service succeeded"
        '';
      };
    };

    # usage
    systemd.services."ntfy-systemd-test" = {
      unitConfig = {
        OnFailure = [ "ntfy-systemd-failure@%i.service" ];
        OnSuccess = [ "ntfy-systemd-success@%i.service" ];
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/false";
      };
    };
  };
}
