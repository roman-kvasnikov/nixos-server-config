{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.uptime-kuma-ctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.uptime-kuma-ctl = {
    enable = lib.mkEnableOption "Enable Uptime Kuma";

    domain = lib.mkOption {
      description = "Domain of the Uptime Kuma module";
      type = lib.types.str;
      default = "uptime-kuma.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Uptime Kuma module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Uptime Kuma module";
      type = lib.types.port;
      default = 3001;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Uptime Kuma";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Uptime Kuma";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Uptime Kuma";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Uptime monitoring";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "uptime-kuma.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Monitoring";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.uptime-kuma = {
        enable = true;

        settings = {
          HOST = cfg.host;
          PORT = toString cfg.port;
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.uptime-kuma = {
          paths = [config.services.uptime-kuma.settings.DATA_DIR];
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
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
