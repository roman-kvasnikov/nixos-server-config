{
  services = {
    # User Services
    cockpitctl.enable = true;
    opensshctl.enable = true;
    fishctl.enable = true;
    immichctl.enable = true;
    jellyfinctl.enable = true;
    minidlnactl.enable = true;
    sambactl = {
      enable = true;

      users = ["romank"];

      shares = {
        public = {
          "path" = "/home/public";
        };

        romank = {
          "path" = "/home/romank";
          "public" = "no";
          "guest ok" = "no";
          "force user" = "romank";
          "force group" = "romank";
          "valid users" = ["romank"];
        };
      };
    };

    # Additional Services
    udisks2.enable = true; # Автоматическое монтирование USB
    geoclue2.enable = true; # Геолокация для часовых поясов
  };
}
