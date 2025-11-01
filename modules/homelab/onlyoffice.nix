{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.onlyofficectl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.onlyofficectl = {
    enable = lib.mkEnableOption "Enable Only Office";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Only Office module";
      default = "onlyoffice.${cfgHomelab.domain}";
    };

    # homepage = {
    #   name = lib.mkOption {
    #     type = lib.types.str;
    #     default = "Only Office";
    #   };
    #   description = lib.mkOption {
    #     type = lib.types.str;
    #     default = "Photo and video management solution";
    #   };
    #   icon = lib.mkOption {
    #     type = lib.types.str;
    #     default = "immich.svg";
    #   };
    #   category = lib.mkOption {
    #     type = lib.types.str;
    #     default = "Clouds";
    #   };
    #   widget = lib.mkOption {
    #     type = lib.types.attrs;
    #     default = {
    #       type = "immich";
    #       url = "https://${cfg.host}";
    #       key = "OzGTW9auqbtAWBbW8GBmxYMzyxTjKBn9JL728psss";
    #       version = 2;
    #     };
    #   };
    # };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.onlyoffice = {
        enable = true;

        hostname = cfg.host;

        # jwtSecretFile = "/home/romank/nixos/secrets/onlyoffice/jwt-secret";
      };

      systemd.services.onlyoffice-docservice = let
        createLocalDotJson = pkgs.writeShellScript "onlyoffice-prestart2" ''
          umask 077
          mkdir -p /run/onlyoffice/config/

          cat >/run/onlyoffice/config/local.json <<EOL
          {
            "services": {
              "CoAuthoring": {
                "token": {
                  "enable": {
                    "browser": true,
                    "request": {
                      "inbox": true,
                      "outbox": true
                    }
                  }
                },
                "secret": {
                  "inbox": {
                    "string": "123"
                  },
                  "outbox": {
                    "string": "123"
                  },
                  "session": {
                    "string": "123"
                  }
                }
              }
            }
          }
          EOL
        '';
      in {
        serviceConfig.ExecStartPre = [createLocalDotJson];
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
          };
        };
      };
    })
  ];
}
