# [Examples](https://github.com/nix-community/disko/tree/master/example)
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-FORESEE_128GB_SSD_AA000000000000000794";
      content = {
        type = "gpt";
        partitions = {
          MBR = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          ESP = {
            priority = 1;
            name = "ESP";
            start = "1M";
            end = "128M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              mountpoint = "/";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
          };
        };
      };
    };
  };
}
