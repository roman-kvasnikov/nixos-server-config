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

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of the Microbin module";
      default = "microbin.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Microbin module";
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port of the Microbin module";
      default = 8069;
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Microbin";
      default = true;
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

        settings = {
          MICROBIN_PUBLIC_PATH = "https://${cfg.domain}/";
          MICROBIN_BIND = cfg.host;
          MICROBIN_PORT = cfg.port;
          MICROBIN_WIDE = true;
          MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
          MICROBIN_HIDE_LOGO = true;
          MICROBIN_HIDE_HEADER = true;
          MICROBIN_HIDE_FOOTER = true;
          MICROBIN_HIGHLIGHTSYNTAX = true;
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
            enableACME = true;
            forceSSL = true;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              deny all;
            '';

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                client_max_body_size 1024M;
              '';
            };
          };
        };
      };
    })
  ];
}
