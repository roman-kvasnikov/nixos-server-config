{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.microbinctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.microbinctl = {
    enable = lib.mkEnableOption "Enable Microbin";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Microbin module";
      default = "microbin.${cfgHomelab.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Data directory for Microbin";
      default = "/data/microbin";
    };

    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = lib.literalExpression ''
        pkgs.writeText "microbin-secret.txt" '''
          MICROBIN_ADMIN_USERNAME
          MICROBIN_ADMIN_PASSWORD
          MICROBIN_UPLOADER_PASSWORD
        '''
      '';
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Microbin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Secure text and file sharing web application";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "microbin.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.microbin = {
        enable = true;

        dataDir = cfg.dataDir;

        settings =
          {
            MICROBIN_WIDE = true;
            MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
            MICROBIN_PUBLIC_PATH = "https://${cfg.host}/";
            MICROBIN_BIND = "127.0.0.1";
            MICROBIN_PORT = 8069;
            MICROBIN_HIDE_LOGO = true;
            MICROBIN_HIGHLIGHTSYNTAX = true;
            MICROBIN_HIDE_HEADER = true;
            MICROBIN_HIDE_FOOTER = true;
          }
          // lib.attrsets.optionalAttrs (cfg.passwordFile != "") {
            passwordFile = cfg.passwordFile;
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
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.microbin.settings.MICROBIN_PORT}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

                client_max_body_size  1024M;
              '';
            };
          };
        };
      };
    })
  ];
}
