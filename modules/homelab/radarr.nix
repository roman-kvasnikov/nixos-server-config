{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.radarrctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.radarrctl = {
    enable = lib.mkEnableOption "Enable Radarr";

    domain = lib.mkOption {
      description = "Domain of the Radarr module";
      type = lib.types.str;
      default = "radarr.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Radarr module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Radarr module";
      type = lib.types.port;
      default = 7878;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Radarr";
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
        default = "Radarr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "A fork of Sonarr to work with movies à la Couchpotato.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "radarr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "radarr";
          url = "https://${cfg.domain}";
          key = "verysecret";
          enableQueue = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.radarr = {
        enable = true;

        user = "radarr";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        settings = {
          update = {
            automatically = true;
            mechanism = "external";
          };
          server = {
            urlbase = "https://${cfg.domain}";
            bindaddress = cfg.host;
            port = cfg.port;
          };
          log.analyticsEnabled = true;
        };

        environmentFiles = [];
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
