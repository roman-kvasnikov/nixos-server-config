{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.microbinctl;
in {
  options.homelab.services.microbinctl = {
    enable = lib.mkEnableOption "Enable Microbin";

    domain = lib.mkOption {
      description = "Domain of the Microbin module";
      type = lib.types.str;
      default = "microbin.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Microbin module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Microbin module";
      type = lib.types.port;
      default = 8069;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Data directory of the Microbin module";
      default = "/mnt/data/AppData/Microbin";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Microbin";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Microbin";
      type = lib.types.bool;
      default = true;
    };

    passwordFile = lib.mkOption {
      description = "Password file for Microbin";
      type = lib.types.path;
      default = config.age.secrets.microbin-env.path;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
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
      users = {
        users.microbin = {
          isSystemUser = true;
          group = "microbin";
        };

        groups.microbin = {};
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 700 microbin microbin - -"
      ];

      services.microbin = {
        enable = true;

        passwordFile = cfg.passwordFile;

        dataDir = cfg.dataDir;

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
          MICROBIN_PRIVATE = true;
          MICROBIN_READONLY = true;
        };
      };

      age.secrets.microbin-env = {
        file = ../../../secrets/microbin.env.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.microbin = {
          paths = [config.services.microbin.dataDir];
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
            enableACME = true;
            forceSSL = true;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

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
