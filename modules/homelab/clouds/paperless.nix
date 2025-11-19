{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.paperlessctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
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
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Paperless";
      type = lib.types.bool;
      default = true;
    };

    systemUser = lib.mkOption {
      description = "System user for Paperless";
      type = lib.types.str;
      default = "paperless";
    };

    passwordFile = lib.mkOption {
      description = "Password file for Paperless";
      type = lib.types.path;
      default = config.age.secrets.admin-password.path;
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
        default = "Document management system";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "paperless.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        paperless = {
          enable = true;

          user = cfg.systemUser;

          passwordFile = cfg.passwordFile;

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

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              deny all;
            '';
          };
        };
      };
    })
  ];
}
