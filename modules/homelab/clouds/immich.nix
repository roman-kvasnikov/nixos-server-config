{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.immichctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
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
      default = "/data/AppData/Immich";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Immich";
      type = lib.types.bool;
      default = true;
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
          key = "OzGTW9auqbtAWBbW8GBmxYMzyxTjKBn9JL728psss";
          version = 2;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        immich
        python313Packages.redis
      ];

      # Fix for machine-learning
      systemd.services.immich-machine-learning = {
        environment = {
          PYTHONPATH = lib.mkForce "${pkgs.python3Packages.redis}/lib/python3.13/site-packages:${pkgs.immich.machine-learning}/lib/python3.13/site-packages";
          MPLCONFIGDIR = "/var/cache/immich/matplotlib";
        };
        serviceConfig = {
          CacheDirectory = "immich";
        };
      };

      users.users.immich.extraGroups = ["video" "render"];

      services.immich = {
        enable = true;

        host = cfg.host;
        port = cfg.port;

        user = "immich";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        mediaLocation = cfg.dataDir;

        environment = {
          PUBLIC_IMMICH_SERVER_URL = "http://${cfg.host}:${toString cfg.port}";
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.immich = {
          database = config.services.immich.database.name;
          paths = [cfg.dataDir];
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
