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

      # delugectl.enable = false;
      # immichctl.enable = true;

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

      # unifictl.enable = false;
      # uptime-kumactl.enable = true;
      xrayctl.enable = false;

      # Additional services
      # dbus.enable = true; # Для работы с systemd
      # udisks2.enable = true; # Автоматическое монтирование USB
      # geoclue2.enable = true; # Геолокация для часовых поясов
    };

    systemd.tmpfiles.rules = [
      "d /media 0755 root root - -"
      "d /media/.torrents 0770 ${config.server.systemUser} ${config.server.systemGroup} - -"
      "d /media/Downloads 0770 ${config.server.systemUser} ${config.server.systemGroup} - -"
      "d /media/Movies 0770 ${config.server.systemUser} ${config.server.systemGroup} - -"
      "d /media/TV\ Shows 0770 ${config.server.systemUser} ${config.server.systemGroup} - -"
      "d /media/Cartoons 0770 ${config.server.systemUser} ${config.server.systemGroup} - -"
    ];

    homelab = {
      services = {
        cockpitctl.enable = true;
        filebrowserctl.enable = true;
        homepagectl.enable = true;
        immichctl.enable = true;
        jellyfinctl.enable = true;
        nextcloudctl.enable = true;
        qbittorrentctl.enable = true;
        tdarrctl.enable = true;
        uptime-kumactl.enable = true;
        vaultwardenctl.enable = true;
      };
    };
  };
}
