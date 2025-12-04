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
  cfg = config.homelab.services.paperlessctl;
in {
  options.homelab.services.paperlessctl = {
    enable = lib.mkEnableOption "Enable Paperless";

    domain = lib.mkOption {
      description = "Domain of the Paperless module";
      type = lib.types.str;
      default = "paperless.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Paperless module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Paperless module";
      type = lib.types.port;
      default = 28981;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Paperless module";
      type = lib.types.str;
      default = "/mnt/data/AppData/Paperless";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Paperless";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Paperless";
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
        default = "Paperless";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Documents management solution";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "paperless.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "paperlessngx";
          url = "https://${cfg.domain}";
          key = "1f0bd45961a6cb5b1f88ef5ed3db9426771e2700";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        paperless = {
          enable = true;

          passwordFile = config.age.secrets.admin-password.path;

          dataDir = cfg.dataDir;

          consumptionDirIsPublic = true;

          configureNginx = cfgNginx.enable;

          domain = cfg.domain;
          address = cfg.host;
          port = cfg.port;

          database.createLocally = true;

          settings = {
            PAPERLESS_URL = "https://${cfg.domain}";
            PAPERLESS_ADMIN_USER = cfgHomelab.adminUser;
            PAPERLESS_DBHOST = lib.mkForce "127.0.0.1:6432";
            PAPERLESS_CONSUMER_IGNORE_PATTERN = [
              ".DS_STORE/*"
              "desktop.ini"
            ];
            PAPERLESS_OCR_LANGUAGE = "rus+eng";
            PAPERLESS_OCR_USER_ARGS = {
              optimize = 1;
              pdfa_image_compression = "lossless";
            };
          };
        };

        postgresql = {
          identMap = lib.mkAfter ''
            pgbouncer pgbouncer paperless
            pgbouncer paperless paperless
          '';
        };

        pgbouncer.settings = {
          databases = {
            paperless = "host=/run/postgresql port=5432 dbname=paperless";
          };
        };

        fail2ban = {
          enable = true;

          jails.paperless.settings = {
            enabled = true;

            backend = "auto";
            port = "80,443";
            protocol = "tcp";
            filter = "paperless";
            maxretry = 3;
            bantime = 3600; # 1 hour
            findtime = 600; # 10 minutes
            logpath = "${cfg.dataDir}/log/paperless.log";
          };
        };
      };

      environment.etc."fail2ban/filter.d/paperless.conf".text = lib.mkDefault (lib.mkAfter ''
        [Definition]
        failregex = \[.*\] \[INFO\] \[paperless\.auth\] Login failed for user `.*` from IP `<HOST>`
        ignoreregex =
      '');

      environment.etc."pgbouncer/userslist.txt".text = lib.mkAfter ''
        "paperless" ""
      '';
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.paperless = {
          database = config.services.paperless.settings.PAPERLESS_DBNAME;
          paths = [config.services.paperless.dataDir];
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
