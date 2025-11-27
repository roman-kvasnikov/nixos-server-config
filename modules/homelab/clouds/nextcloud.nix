{
  config,
  lib,
  pkgs,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.nextcloudctl;
in {
  options.homelab.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    domain = lib.mkOption {
      description = "Domain of the Nextcloud module";
      type = lib.types.str;
      default = "nextcloud.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Nextcloud module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Nextcloud module";
      type = lib.types.port;
      default = 8090;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Nextcloud module";
      type = lib.types.str;
      default = "/mnt/data/AppData/Nextcloud";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Nextcloud";
      type = lib.types.bool;
      default = false;
    };

    adminUser = lib.mkOption {
      description = "Admin user for Nextcloud";
      type = lib.types.str;
      default = cfgHomelab.adminUser;
    };

    adminPasswordFile = lib.mkOption {
      description = "Admin password file for Nextcloud";
      type = lib.types.path;
      default = config.age.secrets.admin-password.path;
    };

    apps = lib.mkOption {
      description = "List of Nextcloud apps to enable";
      type = lib.types.listOf lib.types.str;
      default = ["calendar" "contacts" "notes" "onlyoffice"];
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Nextcloud";
      type = lib.types.bool;
      default = true;
    };

    logFile = lib.mkOption {
      description = "Log file for Nextcloud";
      type = lib.types.path;
      default = "${cfg.dataDir}/data/nextcloud.log";
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
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
          url = "https://${cfg.domain}";
          username = cfg.adminUser;
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

          hostName = cfg.domain;
          https = true;

          home = cfg.dataDir;

          extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
          appstoreEnable = true;
          extraAppsEnable = true;
          autoUpdateApps.enable = true;

          maxUploadSize = "16G";

          caching.redis = true;
          configureRedis = true;

          database.createLocally = true;

          config = {
            adminuser = cfg.adminUser;
            adminpassFile = cfg.adminPasswordFile;
            dbtype = "pgsql";
            dbname = "nextcloud";
            dbuser = "nextcloud";
          };

          settings = {
            maintenance = false; # Disable maintenance mode

            "upgrade.disable-web" = lib.mkForce false;

            # trusted_domains = [
            #   "localhost"
            #   "127.0.0.1"
            #   "${cfgHomelab.subnet}"
            #   "${cfgHomelab.vpnSubnet}"
            # ];

            overwriteprotocol = "https";
            default_phone_region = "RU";
            "profile.enabled" = true;

            # Logging configuration
            loglevel = 2;
            log_type = "file";
            logfile = cfg.logFile;
          };

          phpOptions = {
            "opcache.interned_strings_buffer" = 16;
          };

          nginx = {
            enableFastcgiRequestBuffering = true;
          };
        };

        fail2ban = {
          enable = true;

          jails.nextcloud.settings = {
            enabled = true;

            backend = "auto";
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

      environment.etc."fail2ban/filter.d/nextcloud.conf".text = lib.mkDefault (lib.mkAfter ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
      '');
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.nextcloud = {
          database = config.services.nextcloud.config.dbname;
          paths = [config.services.nextcloud.home];
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
          };
        };
      };
    })
  ];
}
