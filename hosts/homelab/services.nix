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
      # hddfancontrolctl.enable = false;
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
        jellyfinctl.enable = true;

        # nextcloudctl = {
        #   enable = true;

        #   adminUser = cfgHomelab.adminUser;
        #   adminPasswordFile = cfgHomelab.adminPasswordFile;

        #   # homepage.widget = {
        #   #   username = cfgHomelab.adminUser;
        #   #   password = config.age.secrets.nextcloud-admin-password.text;
        #   # };
        # };

        qbittorrentctl.enable = true;

        sambactl = {
          enable = true;

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

        uptime-kumactl.enable = true;
        vaultwardenctl.enable = true;

        # frigatectl = {
        #   enable = true;

        #   cameras = {
        #     hall = {
        #       enable = true;

        #       streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";

        #       onvif = {
        #         enable = true;

        #         host = "192.168.1.31";
        #         port = 2020;
        #         user = "RomanK";
        #         password = "Um9tYW4Um";
        #       };

        #       recordEnabled = true;

        #       detectResolution = {
        #         width = 2560;
        #         height = 1440;
        #       };

        #       audioEnabled = true;

        #       snapshotsEnabled = true;
        #     };
        #   };

        #   recording.enable = true;
        #   detection.enable = true;
        #   snapshots.enable = true;
        # };

        microbinctl.enable = true;
        paperlessctl.enable = true;
      };
    };
  };
}
