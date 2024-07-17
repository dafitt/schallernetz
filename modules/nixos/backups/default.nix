{ options, config, lib, pkgs, host, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.backups;
in
{
  options.schallernetz.backups = with types; {
    localhost = mkBoolOpt true "Enable backups to localhost.";
    NAS4 = mkBoolOpt true "Enable backups to NAS4.";

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
  };

  config = mkMerge [
    (mkIf cfg.localhost {
      age.secrets."borgbackup-job-localhost".file = ./${host}.age;

      systemd.services."borgbackup-job-localhost" = {
        unitConfig = {
          OnFailure = [ "ntfy-systemd-failure@%i.service" ];
          OnSuccess = [ "ntfy-systemd-success@%i.service" ];
        };
      };
      services.borgbackup.jobs."localhost" = {
        repo = "/backups/${host}";
        preHook = "mkdir -p /backups/${host}";
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
      };
    })
    (mkIf cfg.NAS4 {
      age.secrets."borgbackup-job-NAS4".file = ./${host}.age;

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
          RequiresMountsFor = [ "mnt-NAS4.mount" ]; # autostart
          OnFailure = [ "ntfy-systemd-failure@%i.service" ];
          OnSuccess = [ "ntfy-systemd-success@%i.service" ];
        };
        serviceConfig = {
          ReadWritePaths = [ "/mnt/NAS4" ];
        };
      };
      services.borgbackup.jobs."NAS4" = {
        repo = "/mnt/NAS4/${host}";
        preHook = "mkdir -p /mnt/NAS4/${host}";
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
      };
    })
  ];
}
