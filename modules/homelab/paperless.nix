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

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Paperless module";
      default = "paperless.${cfgHomelab.domain}";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User for Paperless";
      default = "paperless";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Password file for Paperless";
      default = config.age.secrets.server-admin-password.path;
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      description = "Media directory for Paperless";
      default = "/mnt/Documents/Paperless/Documents";
    };

    consumptionDir = lib.mkOption {
      type = lib.types.path;
      description = "Consumption directory for Paperless";
      default = "/mnt/Documents/Paperless/Import";
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
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.paperless = {
        enable = true;

        user = cfg.user;
        passwordFile = cfg.passwordFile;

        mediaDir = cfg.mediaDir;
        consumptionDir = cfg.consumptionDir;
        consumptionDirIsPublic = true;

        configureNginx = cfgNginx.enable;
        domain = cfg.host;

        settings = {
          PAPERLESS_URL = "https://${cfg.host}";
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
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
          };
        };
      };
    })
  ];
}
