{
  services = {
    # Prometheus для метрик
    prometheus = {
      enable = true;
      port = 9080;
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:9100"];
            }
          ];
        }
      ];
    };

    # Node exporter для системных метрик
    prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "systemd"
        "cpu"
        "meminfo"
        "diskstats"
        "filesystem"
        "loadavg"
        "netdev"
      ];
    };

    # Grafana для визуализации
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
        };
        security = {
          admin_password = "123"; # Установите переменную окружения
        };
      };
    };

    # Journald для централизованных логов
    journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=1month
    '';
  };

  # Открыть порты для мониторинга
  networking.firewall.allowedTCPPorts = [9080 3000];
}
