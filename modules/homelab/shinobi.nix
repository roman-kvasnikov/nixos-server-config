{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.shinobictl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.shinobictl = {
    enable = lib.mkEnableOption "Enable Shinobi";

    domain = lib.mkOption {
      description = "Domain of the Shinobi module";
      type = lib.types.str;
      default = "shinobi.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Shinobi module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Shinobi module";
      type = lib.types.port;
      default = 5009;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Shinobi";
      type = lib.types.bool;
      default = false;
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Shinobi";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Network Video Recorder (NVR)";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "shinobi.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        shinobi = {
          image = "shinobisystems/shinobi:latest";
          autoStart = true;
          ports = ["${toString cfg.port}:8080"];
          environment = {
            TZ = config.time.timeZone;
          };
          volumes = [
            "/var/lib/shinobi/config:/config"
            "/var/lib/shinobi/database:/var/lib/mysql"
            "/data/media/Shinobi:/home/Shinobi/videos"
            "/var/lib/shinobi/customAutoLoad:/home/Shinobi/customAutoLoad"
            "/var/lib/shinobi/plugins:/home/Shinobi/plugins"
          ];
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
