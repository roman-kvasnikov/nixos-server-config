{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.prowlarrctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.prowlarrctl = {
    enable = lib.mkEnableOption "Enable Prowlarr";

    domain = lib.mkOption {
      description = "Domain of the Prowlarr module";
      type = lib.types.str;
      default = "prowlarr.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Prowlarr module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Prowlarr module";
      type = lib.types.port;
      default = 9696;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Prowlarr";
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
        default = "Prowlarr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Indexer manager for Radarr and Sonarr";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "prowlarr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "prowlarr";
          url = "https://${cfg.domain}";
          key = "cbd1ffa00c9a48b786cf122336c6c3b7";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.prowlarr = {
        enable = true;

        user = "prowlarr";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        settings = {
          update = {
            automatically = true;
            mechanism = "external";
          };
          server = {
            urlbase = "/";
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
