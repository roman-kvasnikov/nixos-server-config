# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.nextcloudctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Nextcloud module";
      default = "nextcloud.${cfgHomelab.domain}";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      description = "Admin user for Nextcloud";
      default = cfgHomelab.adminUser;
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for Nextcloud";
      default = cfgHomelab.adminPasswordFile;
    };

    dbPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Database password file for Nextcloud";
      default = config.age.secrets.postgresql-nextcloud-password.path;
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nextcloud apps to enable";
      default = ["bookmarks" "calendar" "contacts" "notes" "mail" "onlyoffice" "groupfolders"];
    };

    logFile = lib.mkOption {
      type = lib.types.path;
      description = "Log file for Nextcloud";
      default = "/var/lib/nextcloud/data/nextcloud.log";
    };

    performance = {
      maxUploadSize = lib.mkOption {
        type = lib.types.str;
        description = "Maximum upload size";
        default = "16G";
      };

      phpMemoryLimit = lib.mkOption {
        type = lib.types.str;
        description = "PHP memory limit";
        default = "512M";
      };

      opcacheMemory = lib.mkOption {
        type = lib.types.int;
        description = "OPcache memory consumption in MB";
        default = 128;
      };
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
        default = "Clouds";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "nextcloud";
          url = "https://${cfg.host}";
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

          extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
          extraAppsEnable = true;
          autoUpdateApps.enable = true;

          maxUploadSize = cfg.performance.maxUploadSize;

          caching.redis = true;
          configureRedis = true;

          database.createLocally = true;

          config = {
            adminuser = cfg.adminUser;
            adminpassFile = cfg.adminPasswordFile;
            # dbtype = "sqlite";
            dbtype = "pgsql";
            dbname = "nextcloud";
            dbuser = "nextcloud";
            dbpassFile = cfg.dbPasswordFile;
            dbhost = "/run/postgresql";
          };

          # PHP OPcache configuration
          phpOptions = {
            "opcache.enable" = "1";
            "opcache.interned_strings_buffer" = "16";
            "opcache.max_accelerated_files" = "10000";
            "opcache.memory_consumption" = toString cfg.performance.opcacheMemory;
            "opcache.save_comments" = "1";
            "opcache.revalidate_freq" = "60";
            "opcache.jit" = "1255";
            "opcache.jit_buffer_size" = "128M";
            "memory_limit" = cfg.performance.phpMemoryLimit;
            "upload_max_filesize" = cfg.performance.maxUploadSize;
            "post_max_size" = cfg.performance.maxUploadSize;
            "max_execution_time" = "3600";
            "max_input_time" = "3600";
          };

          settings = {
            trusted_domains = [
              "localhost"
              "127.0.0.1"
              "172.20.0.0/16"
              "192.168.1.0/24"
            ];

            overwriteprotocol = "https";
            default_phone_region = "RU";
            "profile.enabled" = true;

            # Logging configuration
            loglevel = 2;
            log_type = "file";
            logfile = cfg.logFile;
          };

          nginx = {
            enableFastcgiRequestBuffering = true;
          };
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
            http2 = true;
          };
        };
      };
    })
  ];
}
