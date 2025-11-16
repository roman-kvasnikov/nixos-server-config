{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.system = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446325";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };

          swap = {
            size = "16G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };

          root = {
            size = "100% - 10G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    disk.data0 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446326";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 10G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.data1 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446326";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 10G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.data2 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446326";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 10G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    zpool = {
      zdata = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/data";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zdata@blank$' || zfs snapshot zdata@blank";
        datasets = {
          nextcloud = {
            type = "zfs_fs";
            mountpoint = "/nextcloud";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "nextcloud";
              mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
