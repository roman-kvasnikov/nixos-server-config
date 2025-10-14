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

    logFile = lib.mkOption {
      type = lib.types.str;
      description = "Log file for Nextcloud";
      default = "/var/lib/nextcloud/data/nextcloud.log";
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

            trusted_domains = [
              cfg.host
              "localhost"
              "127.0.0.1"
              "172.20.0.0/16"
            ];

            loglevel = 2;
            log_type = "file";
            logfile = cfg.logFile;
            logtimezone = "Europe/Moscow";
          };

          maxUploadSize = "16G";

          extraAppsEnable = true;
          autoUpdateApps.enable = true;
          extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
        };

        fail2ban = {
          enable = true;

          jails.nextcloud.settings = {
            backend = "auto";
            enabled = true;
            port = "80,443";
            protocol = "tcp";
            filter = "nextcloud";
            maxretry = 3;
            bantime = 3600; # 1 hour
            findtime = 600; # 10 minutes
            logpath = cfg.logFile;
          };
        };
      };

      environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
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

            extraConfig = ''
              add_header Referrer-Policy                   "no-referrer"       always;
              add_header X-Content-Type-Options            "nosniff"           always;
              add_header X-Frame-Options                   "SAMEORIGIN"        always;
              add_header X-Permitted-Cross-Domain-Policies "none"              always;
              add_header X-Robots-Tag                      "noindex, nofollow" always;
              add_header Strict-Transport-Security         "max-age=15552000; includeSubDomains; preload" always;
            '';
          };
        };
      };
    })
  ];
}
