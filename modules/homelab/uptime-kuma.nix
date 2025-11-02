{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.uptime-kumactl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.uptime-kumactl = {
    enable = lib.mkEnableOption "Enable Uptime Kuma";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Uptime Kuma module";
      default = "uptime-kuma.${cfgHomelab.domain}";
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Uptime Kuma.";
      default = false;
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
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        uptime-kuma
      ];

      services.uptime-kuma = {
        enable = true;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            http2 = true;

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.uptime-kuma.settings.PORT}";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                ${
                  if cfg.allowExternal
                  then ""
                  else ''
                    allow ${cfgHomelab.subnet};
                    deny all;
                  ''
                }
              '';
            };
          };
        };
      };
    })
  ];
}
