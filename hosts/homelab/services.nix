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
        nextcloudctl.enable = true;
        qbittorrentctl.enable = true;

        sambactl = {
          enable = true;

          users = {
            romank = {
              passwordFile = "/etc/secrets/samba/romank-password";
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

            RomanKPrivate = {
              path = "/mnt/Shares/RomanK";
              comment = "RomanK's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["romank"];
              forceUser = "romank";
              forceGroup = "users";
            };
          };
        };

        # tdarrctl.enable = true;
        # unifictl.enable = false;
        uptime-kumactl.enable = true;
        vaultwardenctl.enable = true;
      };
    };
  };
}
