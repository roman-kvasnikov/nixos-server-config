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
    # Nextcloud для облачного хранилища
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      hostName = "nextcloud.local"; # Или ваш домен
      config = {
        adminpassFile = "/etc/nixos/secrets/nextcloud-admin-pass";
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
      };
      database.createLocally = true;
      configureRedis = true;
    };

    postgresql = {
      enable = true;

      ensureDatabases = ["nextcloud"];
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
        }
      ];
    };

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
