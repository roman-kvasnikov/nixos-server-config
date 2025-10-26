{
  config,
  lib,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  imports = [
    ../../modules/homelab
    ../../modules/programs
    ../../modules/services
  ];

  config = {
    services = {
      acmectl.enable = true;
      nginxctl.enable = true;
      hddfancontrolctl.enable = false;
      xrayctl.enable = true;

      # Additional services
      dbus.enable = true; # Для работы с systemd
      udisks2.enable = true; # Автоматическое монтирование USB
      geoclue2.enable = true; # Геолокация для часовых поясов
    };

    homelab = {
      services = {
        filebrowserctl.enable = true;
        homepagectl.enable = true;
        immichctl.enable = true;

        jellyfinctl = {
          enable = true;

          initialDirectory = "/mnt";
        };

        nextcloudctl = {
          enable = true;

          adminUser = cfgHomelab.adminUser;
          adminPasswordFile = cfgHomelab.adminPasswordFile;

          # homepage.widget = {
          #   username = cfgHomelab.adminUser;
          #   password = config.age.secrets.nextcloud-admin-password.text;
          # };
        };

        qbittorrentctl = {
          enable = true;

          initialDirectory = "/mnt";
        };

        sambactl = {
          enable = true;

          initialDirectory = "/mnt";

          users = {
            romank = {
              passwordFile = config.age.secrets.samba-romank-password.path;
            };
            dssmargo = {
              passwordFile = config.age.secrets.samba-dssmargo-password.path;
            };
          };

          shares = {
            Shared = {
              directory = "Shared";
              comment = "Shared files for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

            RomanK = {
              directory = "RomanK";
              comment = "RomanK's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["romank"];
              forceUser = "romank";
              forceGroup = "users";
            };

            DssMargo = {
              directory = "DssMargo";
              comment = "DssMargo's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["dssmargo"];
              forceUser = "dssmargo";
              forceGroup = "users";
            };
          };
        };

        tdarrctl.enable = true;

        uptime-kumactl.enable = true;
        vaultwardenctl.enable = true;

        frigatectl = {
          enable = false;

          cameras = {
            hall = {
              enable = true;

              streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";

              recordEnabled = true;

              detectResolution = {
                width = 1280;
                height = 720;
              };

              snapshotsEnabled = true;
            };
            entrance = {
              enable = true;

              streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.30:554/stream1";

              recordEnabled = true;
            };
          };

          recording.enable = true;
          detection.enable = true;
          snapshots.enable = true;
        };
      };
    };
  };
}
