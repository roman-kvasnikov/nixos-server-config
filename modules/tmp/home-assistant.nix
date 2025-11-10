{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.homeassistantctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.homeassistantctl = {
    enable = lib.mkEnableOption "Enable Home Assistant";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Home Assistant module";
      default = "home-assistant.${cfgHomelab.domain}";
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Home Assistant";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Home automation platform";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "home-assistant.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "homeassistant";
          url = "https://${cfg.host}";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.home-assistant = {
        enable = true;

        openFirewall = !cfgNginx.enable;

        extraComponents = [
          # Components required to complete the onboarding
          "esphome"
          "met"
          "radio_browser"
        ];

        config = {
          # Includes dependencies for a basic setup
          # https://www.home-assistant.io/integrations/default_config/
          default_config = {};
        };
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
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.home-assistant.config.http.server_port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 50000M;
                proxy_read_timeout   600s;
                proxy_send_timeout   600s;
                send_timeout         600s;
                proxy_buffering      off;
              '';
            };
          };
        };
      };
    })
  ];
}
