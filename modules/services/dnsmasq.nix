{
  config,
  lib,
  ...
}: let
  cfg = config.services.dnsmasqctl;
in {
  options.services.dnsmasqctl = {
    enable = lib.mkEnableOption "Enable DNSMasq";
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
          "/kvasok.xyz/192.168.1.11"
          "/*.kvasok.xyz/192.168.1.11"
        ];

        # Слушаем интерфейс локальной сети
        interface = "enp0s20f0u9"; # замени на свой, например enp3s0 или br0
        bind-interfaces = true;

        # Слушаем на этих адресах
        listen-address = [
          "127.0.0.1" # localhost
          "192.168.1.11" # LAN IP
        ];

        # Явно отключаем DHCP (роутер делает)
        no-dhcp-interface = "enp0s20f0u9";

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
