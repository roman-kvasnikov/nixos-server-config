{
  services = {
    # User Services
    cockpitctl.enable = true;
    opensshctl.enable = true;
    fishctl.enable = true;

    # Additional Services
    udisks2.enable = true; # Автоматическое монтирование USB
    geoclue2.enable = true; # Геолокация для часовых поясов
  };
}
