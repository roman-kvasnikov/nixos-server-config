{
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules/homelab
    ../../modules/programs
    ../../modules/services
  ];

  config = {
    services = {
      acmectl.enable = true;
      nginxctl.enable = true;
      hddfancontrolctl.enable = true;
      xrayctl.enable = false;

      # Additional services
      dbus.enable = true; # Для работы с systemd
      udisks2.enable = true; # Автоматическое монтирование USB
      geoclue2.enable = true; # Геолокация для часовых поясов
    };

    homelab = {
      services = {
        cockpitctl.enable = true;
        filebrowserctl.enable = true;
        homepagectl.enable = true;
        immichctl.enable = true;

        jellyfinctl = {
          enable = true;

          initialDirectory = "/mnt";
        };

        nextcloudctl = {
          enable = true;

          adminUser = config.server.adminUser;
          adminPasswordFile = config.server.adminPasswordFile;

          # homepage.widget = {
          #   username = config.server.adminUser;
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

        tdarrctl = {
          enable = true;
        };

        uptime-kumactl.enable = true;
        vaultwardenctl.enable = true;

        frigatectl = {
          enable = true;

          camera1 = {
            enable = true;
            name = "entrance"; # Camera name as shown in your screenshot
            streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";

            detectResolution = {
              width = 1920;
              height = 1080;
            };

            recordEnabled = true;
            snapshotsEnabled = true;

            # Optional: define motion mask to ignore certain areas
            # motionMask = ["0,0,300,0,300,200,0,200"];
          };

          # Configure second camera
          camera2 = {
            enable = true;
            name = "backyard"; # Camera name as shown in your screenshot
            streamUrl = "rtsp://admin:password@192.168.1.32:554/Streaming/Channels/101";

            detectResolution = {
              width = 1920;
              height = 1080;
            };

            recordEnabled = true;
            snapshotsEnabled = true;
          };

          # Detection settings
          detection = {
            enabled = true;
            fps = 5;
            objects = ["person" "car" "cat" "dog" "bicycle"];

            # Optional: Enable Coral TPU for better performance
            # coralDevice = "usb";  # or "pci" for M.2 Coral
          };

          # Recording retention
          recording = {
            retainDays = 7; # Keep recordings for 7 days
            events = {
              retainDays = 14; # Keep event recordings for 14 days
              preCapture = 5; # Record 5 seconds before event
              postCapture = 10; # Record 10 seconds after event
            };
          };

          # Snapshots retention
          snapshots = {
            enabled = true;
            retainDays = 30; # Keep snapshots for 30 days
          };

          # Optional: Enable MQTT for Home Assistant integration
          # mqtt = {
          #   enabled = true;
          #   host = "192.168.1.10";
          #   port = 1883;
          #   user = "frigate";
          #   password = "mqtt_password";
          # };
        };
      };
    };
  };
}
