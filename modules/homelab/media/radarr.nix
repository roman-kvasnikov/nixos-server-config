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

    dataDir = lib.mkOption {
      description = "Data directory of the Radarr module";
      type = lib.types.str;
      default = "/data/AppData/Radarr";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Radarr";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Radarr";
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
        default = "Movie collection manager for BitTorrent users";
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
          key = "cbd1ffa00c9a48b786cf122336c6c3b7";
          enableQueue = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.radarr = {
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

      users.users.radarr = {
        extraGroups = ["downloads" "media"];
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.radarr = {
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
