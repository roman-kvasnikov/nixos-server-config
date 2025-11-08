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
      wireguardctl.enable = cfgHomelab.connectWireguard;

      resolved.enable = false;
      dbus.enable = true; # Для работы с systemd
      udisks2.enable = true; # Автоматическое монтирование USB
      geoclue2.enable = true; # Геолокация для часовых поясов
    };

    homelab = {
      services = {
        sambactl = {
          enable = true;

          shares = {
            Shared = {
              directory = "Shared";
              comment = "Shared files for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };
          };
        };
      };
    };
  };
}
