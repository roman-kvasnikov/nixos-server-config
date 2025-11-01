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
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.onlyoffice = {
        enable = true;

        hostname = cfg.host;

        jwtSecretFile = config.age.secrets.onlyoffice-jwt-secret.path;
      };

      systemd.services.onlyoffice-docservice = let
        createLocalDotJson = pkgs.writeShellScript "onlyoffice-prestart2" ''
          umask 077
          mkdir -p /run/onlyoffice/config/

          # Читаем JWT токен во время выполнения
          JWT_SECRET=$(cat ${config.services.onlyoffice.jwtSecretFile})

          # Используем jq для создания JSON
          ${pkgs.jq}/bin/jq -n \
            --arg secret "''${JWT_SECRET}" \
            '{
              services: {
                CoAuthoring: {
                  token: {
                    enable: {
                      browser: true,
                      request: {
                        inbox: true,
                        outbox: true
                      }
                    }
                  },
                  secret: {
                    inbox: {
                      string: $secret
                    },
                    outbox: {
                      string: $secret
                    },
                    session: {
                      string: $secret
                    }
                  }
                }
              }
            }' > /run/onlyoffice/config/local.json
        '';
      in {
        serviceConfig.ExecStartPre = [createLocalDotJson];
      };

      # systemd.services.onlyoffice-docservice = let
      #   createLocalDotJson = pkgs.writeShellScript "onlyoffice-prestart2" ''
      #     umask 077
      #     mkdir -p /run/onlyoffice/config/

      #     cat >/run/onlyoffice/config/local.json <<EOL
      #     {
      #       "services": {
      #         "CoAuthoring": {
      #           "token": {
      #             "enable": {
      #               "browser": true,
      #               "request": {
      #                 "inbox": true,
      #                 "outbox": true
      #               }
      #             }
      #           },
      #           "secret": {
      #             "inbox": {
      #               "string": "123"
      #             },
      #             "outbox": {
      #               "string": "123"
      #             },
      #             "session": {
      #               "string": "123"
      #             }
      #           }
      #         }
      #       }
      #     }
      #     EOL
      #   '';
      # in {
      #   serviceConfig.ExecStartPre = [createLocalDotJson];
      # };
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
