{
  # https://wiki.nixos.org/wiki/Uninterruptible_power_supply

  power.ups = {
    enable = true;

    mode = "standalone"; # локальная конфигурация с одним UPS :contentReference[oaicite:4]{index=4}
    maxStartDelay = 60; # (необязательно) задержка для запуска драйвера

    openFirewall = true; # Хз для чего, просто из конфигурации сюда добавил чтобы не забыть

    ups = {
      ippon = {
        description = "Ippon Back Basic 650";
        driver = "blazer_usb"; # подходящий драйвер для твоего UPS
        port = "auto";
        # directives можно добавить, если нужны кастомные настройки:
        directives = [
          # например: "offdelay = 60"
          # например: "ondelay = 70"
        ];
      };
    };

    upsd = {
      # настройки сервера, если потребуется (по умолчанию достаточно localhost)
    };

    upsmon = {
      enable = true; # запуск upsmon сервиса :contentReference[oaicite:5]{index=5}
      monitor = {
        ippon = {
          system = "ippon@localhost";
          user = "admin";
          password = "секрет-пароль";
          type = "primary";
          # можно также указать powerValue и т.д.
        };
      };
      settings = {
        SHUTDOWNCMD = "'${pkgs.systemd}/bin/shutdown now'";
        # можно добавить ещё настройки, например FINALDELAY, NOTIFYMSG и др. :contentReference[oaicite:6]{index=6}
      };
    };

    users = {
      admin = {
        password = "password";
        upsmon = "primary"; # если этот сервер — управление UPS
      };
    };
  };

  # Кроме того: убедись, что в BIOS/UEFI включена опция "Restore on AC Power Loss" = Power On
}
