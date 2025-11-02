{
  config,
  lib,
  ...
}: let
  cfg = config.services.dnsmasqctl;
  cfgHomelab = config.homelab;
in {
  options.services.dnsmasqctl = {
    enable = lib.mkEnableOption "Enable local DNS Server";
  };

  config = lib.mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;

      settings = {
        # Основные настройки
        domain-needed = true;
        bogus-priv = true;
        no-resolv = true;

        # Upstream DNS серверы для остальных запросов
        server = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        # Кэширование
        cache-size = 1000;

        # Переопределение для локальной сети
        address = [
          "/${cfgHomelab.domain}/${cfgHomelab.ip}"
          "/*.${cfgHomelab.domain}/${cfgHomelab.ip}"
        ];

        # Слушаем интерфейс локальной сети
        interface = cfgHomelab.interface;
        bind-interfaces = true;

        # Слушаем на этих адресах
        listen-address = [
          "127.0.0.1" # localhost
          cfgHomelab.ip # LAN IP
        ];

        # Явно отключаем DHCP (роутер делает)
        no-dhcp-interface = cfgHomelab.interface;

        # Логирование для отладки
        log-queries = true;
      };
    };

    services.resolved.enable = false;

    # Разрешаем DNS-трафик
    networking.firewall = {
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };
  };
}
