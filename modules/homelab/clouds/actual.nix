{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.actualctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.actualctl = {
    enable = lib.mkEnableOption "Enable Actual";

    domain = lib.mkOption {
      description = "Domain of the Actual module";
      type = lib.types.str;
      default = "actual.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Actual module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Actual module";
      type = lib.types.port;
      default = 3129;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Actual module";
      type = lib.types.str;
      default = "/mnt/data/AppData/Actual";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Actual";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Actual";
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
        default = "Actual";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Personal finance manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "actual.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.actual = {
        enable = true;

        openFirewall = !cfgNginx.enable;

        settings = {
          hostname = cfg.host;
          port = cfg.port;

          config = {
            dataDir = cfg.dataDir;
          };
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.actual = {
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

              extraConfig = ''
                client_max_body_size 50000M;

                # set timeout
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout       600s;
              '';
            };
          };
        };
      };
    })
  ];
}
