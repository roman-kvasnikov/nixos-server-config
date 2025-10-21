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
      };
    };
  };
}
