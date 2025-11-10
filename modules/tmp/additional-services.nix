{
  # В configuration.nix
  services.smartd.enable = true; # Мониторинг дисков

  # Добавьте алерт на заполнение диска
  systemd.timers.check-disk-space = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
    };
  };

  services = {
    # Home Assistant для умного дома
    home-assistant = {
      enable = true;
      extraComponents = [
        "met"
        "esphome"
        "mqtt"
        "zha"
      ];
      config = {
        default_config = {};
        http = {
          server_host = "0.0.0.0";
          server_port = 8123;
        };
      };
    };

    # Pi-hole для блокировки рекламы (альтернатива AdGuard Home)
    adguardhome = {
      enable = true;
      settings = {
        bind_host = "0.0.0.0";
        bind_port = 3001;
        dns = {
          bind_hosts = ["0.0.0.0"];
          port = 53;
          upstream_dns = ["8.8.8.8" "1.1.1.1"];
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443 8123 3001 53];
  networking.firewall.allowedUDPPorts = [53];
}
