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
      name = lib.mkOption {
        type = lib.types.str;
        default = "Speedtest Tracker";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Monitor the performance and uptime of your internet connection";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "speedtest-tracker.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Monitoring";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        speedtest-tracker = {
          image = "lscr.io/linuxserver/speedtest-tracker:latest";
          autoStart = true;
          ports = ["${toString cfg.port}:443"];
          volumes = [
            "/var/lib/speedtest-tracker:/config"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            APP_KEY = "verysecret";
            DB_CONNECTION = "sqlite";
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
              deny all;
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
