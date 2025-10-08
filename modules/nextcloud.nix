# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloudctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Nextcloud module";
      default = "nextcloud.${cfgServer.domain}";
    };

    adminpassFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for Nextcloud";
      default = "/etc/secrets/nextcloud/nextcloud-admin-pass";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nextcloud apps to enable";
      default = ["bookmarks" "calendar" "contacts" "tasks" "notes" "mail"];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.nextcloud = {
        enable = true;

        package = pkgs.nextcloud31;

        hostName = cfg.host;
        https = true;

        caching.redis = true;
        config = {
          dbtype = "pgsql";
          dbname = "nextcloud";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          adminuser = "admin";
          adminpassFile = cfg.adminpassFile;
        };

        settings = {
          overwriteprotocol = "https";
          default_phone_region = "RU";
        };

        maxUploadSize = "16G";

        extraAppsEnable = true;
        autoUpdateApps.enable = true;
        extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});

        extraOptions = {
          redis = {
            host = "127.0.0.1";
            port = 31638;
            dbindex = 0;
            timeout = 1.5;
          };
        };
      };

      services = {
        postgresql = {
          enable = true;
          ensureDatabases = ["nextcloud"];
          ensureUsers = [
            {
              name = "nextcloud";
              ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
            }
          ];
        };
        # optional backup for postgresql db
        postgresqlBackup = {
          enable = true;
          location = "/data/backup/nextclouddb";
          databases = ["nextcloud"];
          # time to start backup in systemd.time format
          startAt = "*-*-* 23:15:00";
        };
      };

      # ensure postgresql db is started with nextcloud
      systemd = {
        services."nextcloud-setup" = {
          requires = ["postgresql.service"];
          after = ["postgresql.service"];
        };
      };

      services = {
        redis.servers.nextcloud = {
          enable = true;
          port = 31638;
          bind = "127.0.0.1";
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
          };
        };
      };
    })
  ];
}
