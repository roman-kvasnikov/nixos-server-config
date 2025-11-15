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

    dataDir = lib.mkOption {
      description = "Data directory of the Uptime Kuma module";
      type = lib.types.str;
      default = "/data/AppData/Uptime-Kuma";
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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
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
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 2775 root root - -"
      ];

      services.uptime-kuma = {
        enable = true;

        settings = {
          HOST = cfg.host;
          PORT = toString cfg.port;
          DATA_DIR = lib.mkForce cfg.dataDir;
        };
      };

      systemd.services.uptime-kuma.serviceConfig.StateDirectory = lib.mkForce cfg.dataDir;
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.uptime-kuma = {
          paths = [cfg.dataDir];
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
