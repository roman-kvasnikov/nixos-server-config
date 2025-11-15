{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.jellyseerrctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.jellyseerrctl = {
    enable = lib.mkEnableOption "Enable Jellyseerr";

    domain = lib.mkOption {
      description = "Domain of the Jellyseerr module";
      type = lib.types.str;
      default = "jellyseerr.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Jellyseerr module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Jellyseerr module";
      type = lib.types.port;
      default = 5055;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Jellyseerr module";
      type = lib.types.str;
      default = "/data/AppData/Jellyseerr";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Jellyseerr";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Jellyseerr";
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
        default = "Jellyseerr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Managing requests for your media library";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "jellyseerr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "jellyseerr";
          url = "https://${cfg.domain}";
          key = "MTc2Mjc5MDIxODA2NzAyMDYzYTQ2LWY0MjgtNDUzNi1hZWUxLTA0MDgzOGFlNGZmYQ==";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 2777 nobody nogroup - -"
      ];

      services.jellyseerr = {
        enable = true;

        port = cfg.port;

        openFirewall = !cfgNginx.enable;

        configDir = cfg.dataDir;
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.jellyseerr = {
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
