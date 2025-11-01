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

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Immich module";
      default = "immich.${cfgHomelab.domain}";
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
          url = "https://${cfg.host}";
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

      services.immich = {
        enable = true;

        host = "127.0.0.1";

        user = "immich";
        group = cfgHomelab.systemGroup;

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
              proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 50000M;
              '';
            };
          };
        };
      };
    })
  ];
}
