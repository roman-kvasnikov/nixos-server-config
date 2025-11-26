let
  createZfsDisk = {
    device,
    pool,
    end ? "-100G",
  }: {
    # zfsDisk = {
    device = device;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          end = end;
          content = {
            type = "zfs";
            pool = pool;
          };
        };
      };
    };
    # };
  };

  createRootFsOptions = {
    acltype ? "posixacl",
    atime ? "off",
    canmount ? "on",
    compression ? "lz4",
    dnodesize ? "auto",
    normalization ? "formD",
    relatime ? "on",
    xattr ? "sa",
    autoSnapshot ? "false",
  }: {
    # rootFsOptions = {
    acltype = acltype;
    atime = atime;
    canmount = canmount;
    compression = compression;
    dnodesize = dnodesize;
    normalization = normalization;
    relatime = relatime;
    xattr = xattr;
    "com.sun:auto-snapshot" = autoSnapshot;
    # };
  };

  createOptions = {
    ashift ? "12",
    autotrim ? "on",
  }: {
    options = {
      ashift = ashift;
      autotrim = autotrim;
    };
  };
in {
  disko.devices = {
    disk.system = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
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
            end = "-20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    disk = {
      data0 = createZfsDisk {
        device = "/dev/sdc";
        pool = "zdata";
      };
      data1 = createZfsDisk {
        device = "/dev/sdd";
        pool = "zdata";
      };
      data2 = createZfsDisk {
        device = "/dev/sde";
        pool = "zdata";
      };
    };

    disk.media = createZfsDisk {
      device = "/dev/sdg";
      pool = "zmedia";
      end = "-500G";
    };

    disk.frigate = createZfsDisk {
      device = "/dev/sdf";
      pool = "zfrigate";
      end = "-5G";
    };

    disk.cache = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          zcache-data = {
            size = "100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };

          zcache-media = {
            size = "100G";
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
                ];
              }
            ];
            cache = ["/dev/disk/by-partlabel/disk-cache-zcache-data"];
          };
        };

        mountpoint = "/mnt/data";
        rootFsOptions = createRootFsOptions;
        options = createOptions;
      };

      zmedia = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = [
                  "/dev/disk/by-partlabel/disk-media-zfs"
                ];
              }
            ];
            cache = ["/dev/disk/by-partlabel/disk-cache-zcache-media"];
          };
        };

        mountpoint = "/mnt/media";
        rootFsOptions = createRootFsOptions {
          compression = "off";
        };
        options = createOptions;
      };

      zfrigate = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = [
                  "/dev/disk/by-partlabel/disk-frigate-zfs"
                ];
              }
            ];
          };
        };

        mountpoint = "/var/lib/frigate";
        rootFsOptions = createRootFsOptions;
        options = createOptions;
      };
    };
  };
}
