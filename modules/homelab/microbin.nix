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
              proxyPass = "http://127.0.0.1:8069";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 50000M;
                proxy_read_timeout   600s;
                proxy_send_timeout   600s;
                send_timeout         600s;
              '';
            };
          };
        };
      };
    })
  ];
}
