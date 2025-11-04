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
      ];

      users.users.immich.extraGroups = ["video" "render"];

      services.immich = {
        enable = true;

        host = cfg.host;
        port = cfg.port;

        user = "immich";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        environment = {
          PUBLIC_IMMICH_SERVER_URL = "http://${cfg.host}:${toString cfg.port}";
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      homelab.services.resticctl = {
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
