{
  lib,
  config,
  ...
}: {
  disko.devices = {
    # Основной системный диск
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

    # Дополнительные диски для данных
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
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446327";
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
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_38446328";
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

    # Создание ZFS пула с настройками
    zpool = {
      zdata = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd"; # Включение сжатия для всего пула
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/data";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zdata@blank$' || zfs snapshot zdata@blank"; # Снимок при создании пула
        datasets = {
          # Cloud-сервисы
          nextcloud = {
            type = "zfs_fs";
            mountpoint = "/nextcloud";
            options = {
              "com.sun:auto-snapshot" = "true"; # Включить авто-снимки
              "userprop:access" = "nextcloud"; # Пропертя для доступа
              mountpoint = "legacy"; # Для монтирования через fstab
            };
          };

          immich = {
            type = "zfs_fs";
            mountpoint = "/immich";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "immich";
              mountpoint = "legacy";
            };
          };

          vaultwarden = {
            type = "zfs_fs";
            mountpoint = "/vaultwarden";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "vaultwarden";
              mountpoint = "legacy";
            };
          };

          linkwarden = {
            type = "zfs_fs";
            mountpoint = "/linkwarden";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "linkwarden";
              mountpoint = "legacy";
            };
          };

          # Медиа-сервисы
          jellyfin = {
            type = "zfs_fs";
            mountpoint = "/jellyfin";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "jellyfin";
              mountpoint = "legacy";
            };
          };

          radarr = {
            type = "zfs_fs";
            mountpoint = "/radarr";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "radarr";
              mountpoint = "legacy";
            };
          };

          sonarr = {
            type = "zfs_fs";
            mountpoint = "/sonarr";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "sonarr";
              mountpoint = "legacy";
            };
          };

          qbittorrent = {
            type = "zfs_fs";
            mountpoint = "/qbittorrent";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "qbittorrent";
              mountpoint = "legacy";
            };
          };

          prowlarr = {
            type = "zfs_fs";
            mountpoint = "/prowlarr";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "prowlarr";
              mountpoint = "legacy";
            };
          };

          # Мониторинг
          glances = {
            type = "zfs_fs";
            mountpoint = "/glances";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "glances";
              mountpoint = "legacy";
            };
          };

          uptime_kuma = {
            type = "zfs_fs";
            mountpoint = "/uptime-kuma";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "uptime-kuma";
              mountpoint = "legacy";
            };
          };

          speedtest_tracker = {
            type = "zfs_fs";
            mountpoint = "/speedtest-tracker";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "speedtest-tracker";
              mountpoint = "legacy";
            };
          };

          # Прочие сервисы
          portainer = {
            type = "zfs_fs";
            mountpoint = "/portainer";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "portainer";
              mountpoint = "legacy";
            };
          };

          pgadmin = {
            type = "zfs_fs";
            mountpoint = "/pgadmin";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "pgadmin";
              mountpoint = "legacy";
            };
          };

          microbin = {
            type = "zfs_fs";
            mountpoint = "/microbin";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "microbin";
              mountpoint = "legacy";
            };
          };

          it_tools = {
            type = "zfs_fs";
            mountpoint = "/it-tools";
            options = {
              "com.sun:auto-snapshot" = "true";
              "userprop:access" = "it-tools";
              mountpoint = "legacy";
            };
          };

          # Samba-сервисы
          shared = {
            type = "zfs_fs";
            mountpoint = "/samba/Shared";
            options = {
              "com.sun:auto-snapshot" = "false";
              "userprop:access" = "shared";
              mountpoint = "legacy";
            };
          };

          roman_k = {
            type = "zfs_fs";
            mountpoint = "/samba/RomanK";
            options = {
              "com.sun:auto-snapshot" = "false";
              "userprop:access" = "roman_k";
              mountpoint = "legacy";
            };
          };

          dss_margo = {
            type = "zfs_fs";
            mountpoint = "/samba/DssMargo";
            options = {
              "com.sun:auto-snapshot" = "false";
              "userprop:access" = "dss_margo";
              mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
