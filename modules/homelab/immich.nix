{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.immichctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.immichctl = {
    enable = lib.mkEnableOption "Enable Immich";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Immich module";
      default = "immich.${cfgServer.domain}";
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
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "immich";
          url = "https://${cfg.host}";
          key = "KnbSIMaSGErVbdgdx7xSf5aH1y01qAbf6Rj4YwWj0";
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

      users.users.immich = {
        isSystemUser = true;
        group = cfgServer.systemGroup;
      };

      # systemd.tmpfiles.rules = ["d ${cfg.mediaDir} 0770 immich ${cfgServer.systemGroup} - -"];

      services.immich = {
        enable = true;

        host = "127.0.0.1";

        user = "immich";
        group = cfgServer.systemGroup;

        openFirewall = !cfgNginx.enable;
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
              proxyPass = "http://127.0.0.1:2283";
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
