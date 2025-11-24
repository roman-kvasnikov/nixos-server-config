{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.sonarrctl;
in {
  options.homelab.services.sonarrctl = {
    enable = lib.mkEnableOption "Enable Sonarr";

    domain = lib.mkOption {
      description = "Domain of the Sonarr module";
      type = lib.types.str;
      default = "sonarr.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Sonarr module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Sonarr module";
      type = lib.types.port;
      default = 8989;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Sonarr";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Sonarr";
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
        default = "Sonarr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "TV show manager for BitTorrent users";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "sonarr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "sonarr";
          url = "https://${cfg.domain}";
          key = "e4cc70bc82d34c00a5ca6629fad9a41a";
          enableQueue = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.sonarr = {
        enable = true;

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

      users.users.sonarr = {
        extraGroups = ["downloads" "media"];
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.sonarr = {
          paths = [config.services.sonarr.dataDir];
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

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

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
