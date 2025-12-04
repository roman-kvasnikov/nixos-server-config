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
  cfg = config.homelab.services.immichctl;
in {
  options.homelab.services.immichctl = {
    enable = lib.mkEnableOption "Enable Immich";

    domain = lib.mkOption {
      description = "Domain of the Immich module";
      type = lib.types.str;
      default = "immich.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Immich module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Immich module";
      type = lib.types.port;
      default = 2283;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Immich module";
      type = lib.types.str;
      default = "/mnt/data/AppData/Immich";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Immich";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Immich";
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
        default = "Immich";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Photo and video management solution";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "immich.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "immich";
          url = "https://${cfg.domain}";
          key = "zBnoyr8KnC5CTmOeR9uPFbh3oTB0W4sUSTqaR66p5w";
          version = 2;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 700 immich immich - -"
      ];

      services = {
        immich = {
          enable = true;

          host = cfg.host;
          port = cfg.port;

          openFirewall = !cfgNginx.enable;

          mediaLocation = cfg.dataDir;

          database = {
            host = "127.0.0.1";
            port = 6432;
          };
        };

        postgresql = {
          identMap = lib.mkAfter ''
            pgbouncer pgbouncer immich
            pgbouncer immich immich
          '';
        };

        pgbouncer.settings = {
          databases = {
            immich = "host=/run/postgresql port=5432 dbname=immich";
          };
        };
      };

      environment.etc."pgbouncer/userslist.txt".text = lib.mkAfter ''
        "immich" ""
      '';

      users.users.immich.extraGroups = ["video" "render"];
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.immich = {
          database = config.services.immich.database.name;
          paths = [config.services.immich.mediaLocation];
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

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                client_max_body_size 50000M;

                # set timeout
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout       600s;
              '';
            };
          };
        };
      };
    })
  ];
}
