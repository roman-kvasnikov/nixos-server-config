{
  pkgs,
  lib,
  ...
}: {
  services = {
    desktopManager.gnome.enable = true;

    # GNOME system services
    gnome = lib.mkForce {
      gnome-keyring.enable = false; # Используем другой keyring

      # GNOME Games
      games.enable = false;

      # Оптимизация для производительности
      at-spi2-core.enable = true;
    };

    # Современная индексация файлов для GNOME Search
    locate = {
      enable = true;
      package = pkgs.mlocate;
      interval = "hourly";
    };
  };
}
