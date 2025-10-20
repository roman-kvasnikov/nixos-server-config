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
      acmectl = {
        enable = true;

        commonCertOptions = {
          dnsProvider = "namecheap";
          credentialsFile = config.age.secrets.acme-namecheap-env.path;
        };
      };

      nginxctl.enable = true;
      hddfancontrolctl.enable = true;
      xrayctl.enable = true;

      # Additional services
      # dbus.enable = true; # Для работы с systemd
      # udisks2.enable = true; # Автоматическое монтирование USB
      # geoclue2.enable = true; # Геолокация для часовых поясов
    };

    homelab = {
      services = {
        cockpitctl.enable = true;
        filebrowserctl.enable = true;
        homepagectl.enable = true;
        immichctl.enable = true;
        jellyfinctl.enable = true;

        nextcloudctl = {
          enable = true;

          adminUser = config.server.adminUser;
          adminPasswordFile = config.age.secrets.server-admin-password.path;

          # homepage.widget = {
          #   username = config.server.adminUser;
          #   password = config.age.secrets.nextcloud-admin-password.text;
          # };
        };

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
            Public = {
              path = "/mnt/Shares/Public";
              comment = "Public Share for Everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

            RomanK = {
              path = "/mnt/Shares/RomanK";
              comment = "RomanK's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["romank"];
              forceUser = "romank";
              forceGroup = "users";
            };

            DssMargo = {
              path = "/mnt/Shares/DssMargo";
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
      };
    };
  };
}
