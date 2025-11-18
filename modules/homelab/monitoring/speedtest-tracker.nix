{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.speedtest-tracker-ctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.speedtest-tracker-ctl = {
    enable = lib.mkEnableOption "Enable Speedtest Tracker";

    domain = lib.mkOption {
      description = "Domain of the Speedtest Tracker module";
      type = lib.types.str;
      default = "speedtest-tracker.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Speedtest Tracker module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Speedtest Tracker module";
      type = lib.types.port;
      default = 8443;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Speedtest Tracker";
      type = lib.types.bool;
      default = false;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Speedtest Tracker";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Monitor the performance of your internet connection";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "speedtest-tracker.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Monitoring";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "speedtest";
          url = "https://${cfg.domain}";
          version = 2;
          key = "jml5excTGosPFHTdw0YdvXtzx6Yni8nDXqVMZ6Zkad216e28";
          bitratePrecision = 3;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        speedtest-tracker = {
          image = "lscr.io/linuxserver/speedtest-tracker:latest";
          autoStart = true;
          ports = [
            "${toString cfg.port}:80"
          ];
          volumes = [
            "/var/lib/speedtest-tracker:/config"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            APP_KEY = "base64:EjvmBkyWtdLycx1Q7ObpLEdgtUvmeJhRQmgYGa7pzg8=";
            DB_CONNECTION = "sqlite";
            ADMIN_NAME = cfgHomelab.adminUser;
            ADMIN_EMAIL = cfgHomelab.email;
            ADMIN_PASSWORD = "123";
            APP_URL = "https://${cfg.domain}";
            ASSET_URL = "https://${cfg.domain}";
            APP_TIMEZONE = config.time.timeZone;
            DISPLAY_TIMEZONE = config.time.timeZone;
            PUBLIC_DASHBOARD = "true";

            SPEEDTEST_SERVERS = "12362";

            APP_DEBUG = "true";
          };
        };
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.domain}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              allow ${cfgHomelab.wireguardSubnet};
              deny all;

              add_header Strict-Transport-Security "max-age=31536000;includeSubdomains";
            '';

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
