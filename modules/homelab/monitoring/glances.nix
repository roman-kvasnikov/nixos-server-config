{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.glancesctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.glancesctl = {
    enable = lib.mkEnableOption "Enable Glances";

    domain = lib.mkOption {
      description = "Domain of the Glances module";
      type = lib.types.str;
      default = "glances.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Glances module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Glances module";
      type = lib.types.port;
      default = 61208;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Glances";
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
        default = "Glances";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "System monitoring";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "glances.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Monitoring";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.glances = {
        enable = true;

        port = cfg.port;

        openFirewall = !cfgNginx.enable;
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
