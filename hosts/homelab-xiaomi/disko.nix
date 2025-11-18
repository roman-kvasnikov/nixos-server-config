{
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
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    disk.data = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100G";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };

          media = {
            size = "100G";
            content = {
              type = "zfs";
              pool = "zmedia";
            };
          };

          # zcache-data = {
          #   size = "10G";
          #   content = {
          #     type = "zfs";
          #     pool = "zdata";
          #   };
          # };

          # zcache-media = {
          #   size = "10G";
          #   content = {
          #     type = "zfs";
          #     pool = "zmedia";
          #   };
          # };
        };
      };
    };

    zpool = {
      zdata = {
        type = "zpool";

        # mode = {
        #   topology = {
        #     type = "topology";
        #     vdev = [
        #       {
        #         members = [
        #           "data"
        #         ];
        #       }
        #     ];
        #     cache = ["zcache-data"];
        #   };
        # };

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

        # mode = {
        #   topology = {
        #     type = "topology";
        #     vdev = [
        #       {
        #         members = [
        #           "media"
        #         ];
        #       }
        #     ];
        #     cache = ["zcache-media"];
        #   };
        # };

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
    };
  };
}
