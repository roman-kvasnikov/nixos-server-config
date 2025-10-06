{
  services = {
    # User Services
    acmectl.enable = true;
    nginxctl.enable = true;

    cockpitctl.enable = true;
    nextcloudctl.enable = true;
    immichctl.enable = true;
    jellyfinctl.enable = true;
    qbittorrentctl.enable = true;
    opensshctl.enable = true;
    fishctl.enable = true;
    minidlnactl.enable = true;
    filebrowserctl.enable = false;

    sambactl = {
      enable = true;

      users = ["romank"];

      shares = {
        public = {
          "path" = "/home/public";
        };

        movies = {
          "path" = "/home/movies";
        };

        romank = {
          "path" = "/home/romank";
          "public" = "no";
          "guest ok" = "no";
          "create mask" = "0770";
          "directory mask" = "0770";
          "force user" = "romank";
          "force group" = "romank";
          "valid users" = ["romank"];
        };
      };
    };

    # Additional Services
    dbus.enable = true; # Для работы с systemd
    udisks2.enable = true; # Автоматическое монтирование USB
    geoclue2.enable = true; # Геолокация для часовых поясов
  };
}
