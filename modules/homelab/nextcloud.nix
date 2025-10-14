# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.nextcloudctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.nextcloudctl = {
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
      default = ["bookmarks" "calendar" "contacts" "notes" "mail" "onlyoffice" "groupfolders"];
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Nextcloud";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Enterprise File Storage and Collaboration";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "nextcloud.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "nextcloud";
          url = "https://${cfg.host}";
          username = "root";
          password = "123";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        nextcloud = {
          enable = true;

          package = pkgs.nextcloud32;

          hostName = cfg.host;
          https = true;

          # Настройка кэширования
          caching.redis = true;
          configureRedis = true; # Автоматическая настройка Redis

          # Настройка базы данных
          database.createLocally = true; # Автоматически создать БД
          config = {
            dbtype = "sqlite";
            adminpassFile = cfg.adminpassFile;
            # dbpassFile = cfg.adminpassFile;
          };

          settings = {
            overwriteprotocol = "https";
            default_phone_region = "RU";

            trusted_domains = [cfg.host];

            loglevel = 2; # WARNING — покажет ошибки входа
            log_type = "file";
            logfile = "/var/lib/nextcloud/data/nextcloud.log";
            logtimezone = "UTC";
          };

          maxUploadSize = "16G";

          extraAppsEnable = true;
          autoUpdateApps.enable = true;
          extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
        };

        fail2ban = {
          enable = true;

          jails.nextcloud = ''
            enabled = true
            filter = nextcloud
            action = iptables[name=nextcloud, port=http, protocol=tcp]
            logpath = /var/lib/nextcloud/data/nextcloud.log
            maxretry = 5
            bantime = 3600
            findtime = 600
          '';
        };
      };

      environment.etc."fail2ban/filter.d/nextcloud-auth.conf".text = ''
        [Definition]
        failregex = "remoteAddr":"<HOST>",.*"message":"Login failed
        ignoreregex =
      '';
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
