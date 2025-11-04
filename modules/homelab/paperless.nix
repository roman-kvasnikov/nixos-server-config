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
      type = lib.types.str;
      description = "Domain of the Paperless module";
      default = "paperless.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Paperless module";
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port of the Paperless module";
      default = 28981;
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Paperless";
      default = true;
    };

    backupEnabled = lib.mkOption {
      type = lib.types.bool;
      description = "Enable backup for Paperless";
      default = true;
    };

    systemUser = lib.mkOption {
      type = lib.types.str;
      description = "System user for Paperless";
      default = "paperless";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Password file for Paperless";
      default = config.age.secrets.server-admin-password.path;
    };

    homepage = {
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
      services.paperless = {
        enable = true;

        user = cfg.systemUser;

        passwordFile = cfg.passwordFile;

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

      homelab.services.resticctl = lib.mkIf cfg.backupEnabled {
        jobs.paperless = {
          enable = true;

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
