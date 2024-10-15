{ options, config, lib, pkgs, host, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.backups;

  mkShutdownCommand = service: ''
    if systemctl is-active --quiet '${service}'; then
      touch '/tmp/${service}-was-active'
      systemctl stop '${service}'
    fi
  '';
  mkRestartCommand = service: ''
    if [ -f '/tmp/${service}-was-active' ]; then
      rm '/tmp/${service}-was-active'
      systemctl start '${service}'
    fi
  '';
in
{
  options.schallernetz.backups = with types; {
    localhost = mkBoolOpt false "Enable backups to localhost.";
    NAS4 = mkBoolOpt false "Enable backups to NAS4.";
    magentacloudMICHI = mkBoolOpt false "Enable backups to magentacloudMICHI.";

    paths = mkOption {
      description = "Which paths to backup.";
      type = listOf str;
      default = [ ];
      example = [
        "/var/lib/nixos-containers/<name>/etc/group"
        "/var/lib/nixos-containers/<name>/etc/machine-id"
        "/var/lib/nixos-containers/<name>/etc/passwd"
        "/var/lib/nixos-containers/<name>/etc/subgid"
        "/var/lib/nixos-containers/<name>/root"
        "/var/lib/nixos-containers/<name>/var/lib"
      ];
    };

    # thank you @tlater
    # https://gitea.tlater.net/tlaternet/tlaternet-server/src/branch/master/configuration/services/backups.nix
    pauseServices = lib.mkOption {
      type = types.listOf types.str;
      default = [ "container@DavidCAL.service" ];
      description = ''
        The systemd services that need to be shut down before
        the backup can run. Services will be restarted after the
        backup is complete.

        This is intended to be used for services that do not
        support hot backups.
      '';
    };

  };

  config = mkMerge [
    (mkIf (cfg.localhost || cfg.NAS4 || cfg.magentacloudMICHI) {
      schallernetz.ntfy-systemd = {
        enable = true;
        url = "http://[${config.schallernetz.servers.ntfy.name}.lan.${config.networking.domain}]";
      };
    })
    (mkIf cfg.localhost {
      age.secrets."borgbackup-job-localhost" = {
        file = ./${host}.age;
      };

      systemd.services."borgbackup-job-localhost" = {
        unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };
      };
      services.borgbackup.jobs."localhost" = {
        repo = "/SchallernetzBACKUPS/${host}";
        encryption.mode = "repokey-blake2";
        encryption.passCommand = "cat ${config.age.secrets."borgbackup-job-localhost".path}";
        compression = "auto,zstd";
        paths = cfg.paths;

        startAt = "daily";
        prune.keep = {
          within = "1w"; # everything
          weekly = 4;
          monthly = 2;
        };

        preHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkShutdownCommand service));
        postHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkRestartCommand service));
      };
      systemd.timers."borgbackup-job-localhost" = {
        timerConfig = {
          RandomizedDelaySec = "60min";
        };
      };
    })

    (mkIf cfg.NAS4 {
      age.secrets."borgbackup-job-NAS4" = { file = ./${host}.age; };

      environment.systemPackages = [ pkgs.nfs-utils ]; # needed for NFS
      services.rpcbind.enable = true; # needed for NFS
      systemd.mounts = [{
        unitConfig = {
          PartOf = [ "borgbackup-job-NAS4.service" ];
          StopWhenUnneeded = true;
        };
        what = "***REMOVED_IPv4***:/SchallernetzBACKUP";
        where = "/mnt/NAS4";
        type = "nfs";
        mountConfig = {
          Options = "noatime";
        };
      }];
      systemd.services."borgbackup-job-NAS4" = {
        unitConfig = {
          RequiresMountsFor = [ "/mnt/NAS4" ]; # autostart
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };
        serviceConfig = {
          ReadWritePaths = [ "/mnt/NAS4" ];
        };
      };
      services.borgbackup.jobs."NAS4" = {
        repo = "/mnt/NAS4/SchallernetzBACKUPS/${host}";
        removableDevice = true;
        encryption.mode = "repokey-blake2";
        encryption.passCommand = "cat ${config.age.secrets."borgbackup-job-NAS4".path}";
        compression = "auto,zstd";
        paths = cfg.paths;

        startAt = "Mon *-*-* ***REMOVED_IPv6***";
        prune.keep = {
          within = "1m"; # everything
          monthly = 12;
          yearly = 2;
        };

        preHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkShutdownCommand service));
        postHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkRestartCommand service));
      };
      systemd.timers."borgbackup-job-NAS4" = {
        timerConfig.RandomizedDelaySec = "15min";
      };
    })

    # https://magentacloud.de/
    (mkIf cfg.magentacloudMICHI {
      age.secrets."borgbackup-job-magentacloudMICHI" = { file = ./${host}.age; };
      age.secrets."davfs-secrets" = { file = ./davfs-secrets.age; };

      # davfs2.conf (5)
      # https://sleeplessbeastie.eu/2017/09/25/how-to-mount-webdav-share-using-systemd/
      services.davfs2.enable = true;
      environment.etc."davfs2/secrets".source = config.age.secrets."davfs-secrets".path;
      # https://cloud.domain/remote.php/webdav/ username password
      systemd.mounts = [{
        unitConfig = {
          PartOf = [ "borgbackup-job-magentacloudMICHI.service" ];
          StopWhenUnneeded = true;
        };
        what = "https://magentacloud.de/remote.php/webdav";
        where = "/mnt/magentacloudMICHI";
        type = "davfs";
        mountConfig = {
          Options = "noatime";
          TimeoutSec = 60;
        };
      }];
      systemd.services."borgbackup-job-magentacloudMICHI" = {
        unitConfig = {
          RequiresMountsFor = [ "/mnt/magentacloudMICHI" ]; # autostart
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };
        serviceConfig = {
          ReadWritePaths = [ "/mnt/magentacloudMICHI" ];
        };
      };
      services.borgbackup.jobs."magentacloudMICHI" = {
        repo = "/mnt/magentacloudMICHI/SchallernetzBACKUPS/${host}";
        removableDevice = true;
        encryption.mode = "repokey-blake2";
        encryption.passCommand = "cat ${config.age.secrets."borgbackup-job-magentacloudMICHI".path}";
        compression = "auto,zstd";
        paths = cfg.paths;

        startAt = "*-*-01/2 ***REMOVED_IPv6***"; # every second day 2 o'clock
        prune.keep = {
          within = "1m"; # everything
          monthly = 12;
          yearly = 2;
        };

        preHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkShutdownCommand service));
        postHook = concatStringsSep "\n" (forEach cfg.pauseServices (service: mkRestartCommand service));
      };
      systemd.timers."borgbackup-job-magentacloudMICHI" = {
        timerConfig.RandomizedDelaySec = "3h";
      };
    })
  ];
}
