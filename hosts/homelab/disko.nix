{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.system = {
      device = "/dev/sda";
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
            size = "100% - 20G";
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
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.data1 = {
      device = "/dev/sdc";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.data2 = {
      device = "/dev/sdd";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.data3 = {
      device = "/dev/sde";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };

    disk.media0 = {
      device = "/dev/sdf";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zmedia";
            };
          };
        };
      };
    };

    disk.media1 = {
      device = "/dev/sdg";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zmedia";
            };
          };
        };
      };
    };

    disk.media2 = {
      device = "/dev/sdh";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 100G";
            content = {
              type = "zfs";
              pool = "zmedia";
            };
          };
        };
      };
    };

    disk.frigate = {
      device = "/dev/sdi";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100% - 20G";
            content = {
              type = "zfs";
              pool = "zfrigate";
            };
          };
        };
      };
    };

    disk.cache = {
      device = "/dev/sdj";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zcache-data = {
            size = "40%";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };

          zcache-media = {
            size = "40%";
            content = {
              type = "zfs";
              pool = "zmedia";
            };
          };
        };
      };
    };

    zpool = {
      zdata = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "raidz1";
                members = [
                  "/dev/disk/by-partlabel/disk-data0-zfs"
                  "/dev/disk/by-partlabel/disk-data1-zfs"
                  "/dev/disk/by-partlabel/disk-data2-zfs"
                  "/dev/disk/by-partlabel/disk-data3-zfs"
                ];
              }
            ];
            cache = ["/dev/disk/by-partlabel/disk-cache-zcache-data"];
          };
        };

        mountpoint = "/mnt/data";

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "on";
          compression = "lz4";
          dnodesize = "auto";
          # mountpoint = "legacy";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          AppData = {
            type = "zfs_fs";
            mountpoint = "/mnt/data/AppData";
            options = {
              # mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          Shares = {
            type = "zfs_fs";
            mountpoint = "/mnt/data/Shares";
            options = {
              # mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };
        };
      };

      zmedia = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = [
                  "/dev/disk/by-partlabel/disk-media0-zfs"
                  "/dev/disk/by-partlabel/disk-media1-zfs"
                  "/dev/disk/by-partlabel/disk-media2-zfs"
                ];
              }
            ];
            cache = ["/dev/disk/by-partlabel/disk-cache-zcache-media"];
          };
        };

        mountpoint = "/mnt/media";

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "on";
          compression = "off";
          dnodesize = "auto";
          # mountpoint = "legacy";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };
      };

      zfrigate = {
        type = "zpool";
        mountpoint = "/var/lib/frigate";

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "on";
          compression = "lz4";
          dnodesize = "auto";
          # mountpoint = "legacy";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };
      };
    };
  };
}
