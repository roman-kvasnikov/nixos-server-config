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

      # sambactl = {
      #   enable = true;

      #   users = ["romank"];

      #   shares = {
      #     public = {
      #       "path" = "/home/public";
      #     };

      #     movies = {
      #       "path" = "/home/movies";
      #     };

      #     romank = {
      #       "path" = "/home/romank";
      #       "public" = "no";
      #       "guest ok" = "no";
      #       "create mask" = "0770";
      #       "directory mask" = "0770";
      #       "force user" = "romank";
      #       "force group" = "romank";
      #       "valid users" = ["romank"];
      #     };
      #   };
      # };

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
        # tdarrctl.enable = true;
        uptime-kumactl.enable = true;
        # unifictl.enable = false;
        vaultwardenctl.enable = true;
      };
    };
  };
}
