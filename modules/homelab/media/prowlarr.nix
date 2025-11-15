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

    dataDir = lib.mkOption {
      description = "Data directory of the Prowlarr module";
      type = lib.types.str;
      default = "/data/AppData/Prowlarr";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Prowlarr";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Prowlarr";
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
          key = "4bc003706b9943fd87d60f904e1c930c";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.prowlarr = {
        enable = true;

        openFirewall = !cfgNginx.enable;

        dataDir = cfg.dataDir;

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

      services.flaresolverr = {
        enable = true;

        openFirewall = !cfgNginx.enable;
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.prowlarr = {
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
