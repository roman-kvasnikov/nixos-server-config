# /etc/nixos/ups.nix
# Подключи этот файл в configuration.nix через imports = [ ./ups.nix ];
# сделать как модуль
{
  config,
  pkgs,
  ...
}: {
  # Включаем NUT
  power.ups = {
    enable = true;
    mode = "standalone";

    # Объявление ИБП
    ups."ippon" = {
      description = "Ippon Back Basic 650";
      driver = "blazer_usb";
      port = "auto";
      directives = [
        # Задержка перед отключением ИБП после команды shutdown (секунды)
        # Даём системе время на корректное завершение
        "offdelay = 120"

        # Задержка перед включением ИБП после восстановления питания
        # Должна быть больше offdelay для корректной работы Wake-on-AC
        "ondelay = 180"

        # Порог низкого заряда батареи (40%)
        # При достижении этого значения upsmon инициирует выключение
        "override.battery.charge.low = 40"

        # Порог предупреждения о низком заряде (45%)
        "override.battery.charge.warning = 45"

        # Игнорировать сигнал LB от ИБП, использовать наш порог
        "ignorelb"

        # Напряжения батареи (типичные для 12V батареи)
        "default.battery.voltage.high = 13.60"
        "default.battery.voltage.low = 10.60"
      ];
    };

    # Настройка демона upsd (прослушивание только localhost)
    upsd = {
      listen = [
        {
          address = "127.0.0.1";
          port = 3493;
        }
        {
          address = "::1";
          port = 3493;
        }
      ];
    };

    # Пользователь для доступа к UPS
    users."upsmon" = {
      # Создай файл с паролем: echo "твой_пароль" > /etc/nixos/secrets/ups-password
      # И убедись, что права доступа ограничены: chmod 600 /etc/nixos/secrets/ups-password
      passwordFile = config.age.secrets.ups-password.path;
      upsmon = "primary";
    };

    # Подключение upsmon к upsd
    upsmon.monitor."ippon" = {
      system = "ippon@localhost";
      powerValue = 1;
      user = "upsmon";
      passwordFile = config.age.secrets.ups-password.path;
      type = "primary";
    };

    # Настройки реакции на события
    upsmon.settings = {
      # Сообщения о событиях
      NOTIFYMSG = [
        ["ONLINE" "ИБП %s: Питание от сети восстановлено."]
        ["ONBATT" "ИБП %s: Работа от батареи!"]
        ["LOWBATT" "ИБП %s: Низкий заряд батареи!"]
        ["REPLBATT" "ИБП %s: Требуется замена батареи."]
        ["FSD" "ИБП %s: Принудительное выключение."]
        ["SHUTDOWN" "Выполняется автоматическое выключение."]
        ["COMMOK" "ИБП %s: Связь восстановлена."]
        ["COMMBAD" "ИБП %s: Связь потеряна."]
        ["NOCOMM" "ИБП %s: Недоступен."]
        ["NOPARENT" "Родительский процесс upsmon мёртв!"]
      ];

      # Куда отправлять уведомления
      NOTIFYFLAG = [
        ["ONLINE" "SYSLOG+WALL"]
        ["ONBATT" "SYSLOG+WALL"]
        ["LOWBATT" "SYSLOG+WALL"]
        ["REPLBATT" "SYSLOG+WALL"]
        ["FSD" "SYSLOG+WALL"]
        ["SHUTDOWN" "SYSLOG+WALL"]
        ["COMMOK" "SYSLOG+WALL"]
        ["COMMBAD" "SYSLOG+WALL"]
        ["NOCOMM" "SYSLOG+WALL"]
        ["NOPARENT" "SYSLOG+WALL"]
      ];

      # Предупреждать о замене батареи каждые 60 часов (216000 сек)
      RBWARNTIME = 216000;

      # Предупреждать о потере связи каждые 5 минут
      NOCOMMWARNTIME = 300;

      # Задержка перед выключением после уведомления (0 = немедленно)
      FINALDELAY = 5;
    };
  };

  # Сервис для отложенного выключения ИБП
  # Это нужно для работы функции "Restore power on AC" в BIOS
  systemd.services.nut-delayed-ups-shutdown = {
    enable = true;
    environment = config.systemd.services.upsmon.environment;
    description = "Отложенное выключение ИБП";
    before = ["umount.target"];
    wantedBy = ["final.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nut}/bin/upsdrvctl -u root shutdown";
    };
    unitConfig = {
      ConditionPathExists = config.power.ups.upsmon.settings.POWERDOWNFLAG;
      DefaultDependencies = "no";
    };
  };

  # Сервис для выключения по таймауту (30 минут на батарее)
  # Использует upssched для отслеживания времени на батарее
  systemd.services.ups-battery-timer = {
    description = "Таймер выключения при работе от батареи";
    wantedBy = ["multi-user.target"];
    after = ["nut-driver.target" "nut-server.service"];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "ups-battery-monitor" ''
        #!/bin/bash
        TIMER_FILE="/tmp/ups-onbatt-timer"
        MAX_ONBATT_SECONDS=1800  # 30 минут

        while true; do
          STATUS=$(${pkgs.nut}/bin/upsc ippon@localhost ups.status 2>/dev/null)

          if echo "$STATUS" | grep -q "OB"; then
            # На батарее
            if [ ! -f "$TIMER_FILE" ]; then
              echo "$(date +%s)" > "$TIMER_FILE"
              echo "ИБП перешёл на батарею, запущен таймер"
            fi

            START_TIME=$(cat "$TIMER_FILE")
            CURRENT_TIME=$(date +%s)
            ELAPSED=$((CURRENT_TIME - START_TIME))

            if [ "$ELAPSED" -ge "$MAX_ONBATT_SECONDS" ]; then
              echo "Прошло 30 минут на батарее, инициируем выключение"
              ${pkgs.systemd}/bin/systemctl poweroff
            fi
          else
            # На сети - сбрасываем таймер
            if [ -f "$TIMER_FILE" ]; then
              rm -f "$TIMER_FILE"
              echo "Питание восстановлено, таймер сброшен"
            fi
          fi

          sleep 30
        done
      '';
      Restart = "always";
      RestartSec = 10;
    };
  };

  # udev правило для USB доступа к ИБП
  services.udev.extraRules = ''
    # Ippon Back Basic 650 (Cypress USB-to-Serial)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0665", ATTR{idProduct}=="5161", MODE="0664", GROUP="nut"
  '';

  age.secrets.ups-password = {
    file = ../../secrets/ups.password.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
