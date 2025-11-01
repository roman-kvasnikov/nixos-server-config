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
          set -x  # Включаем отладку
          umask 077
          mkdir -p /run/onlyoffice/config/

          # Проверяем существование и права на файл
          echo "Secret file path: ${config.age.secrets.onlyoffice-jwt-secret.path}" >&2

          if [ ! -e "${config.age.secrets.onlyoffice-jwt-secret.path}" ]; then
            echo "ERROR: Secret file does not exist!" >&2
            exit 1
          fi

          if [ ! -r "${config.age.secrets.onlyoffice-jwt-secret.path}" ]; then
            echo "ERROR: Cannot read secret file!" >&2
            ls -la ${config.age.secrets.onlyoffice-jwt-secret.path} >&2
            exit 1
          fi

          # Показываем информацию о файле
          echo "File info:" >&2
          ls -la ${config.age.secrets.onlyoffice-jwt-secret.path} >&2

          # Читаем секрет
          JWT_SECRET=$(cat ${config.age.secrets.onlyoffice-jwt-secret.path})

          # Проверяем, что прочитали
          echo "JWT_SECRET length: ''${#JWT_SECRET}" >&2
          echo "JWT_SECRET first 5 chars: ''${JWT_SECRET:0:5}..." >&2

          if [ -z "''${JWT_SECRET}" ]; then
            echo "WARNING: JWT_SECRET is empty after reading!" >&2
            # Пробуем альтернативный способ чтения
            JWT_SECRET=$(<${config.age.secrets.onlyoffice-jwt-secret.path})
            echo "After alternative read, length: ''${#JWT_SECRET}" >&2
          fi

          # Создаём JSON
          cat >/run/onlyoffice/config/local.json <<EOF
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
                    "string": "''${JWT_SECRET}"
                  },
                  "outbox": {
                    "string": "''${JWT_SECRET}"
                  },
                  "session": {
                    "string": "''${JWT_SECRET}"
                  }
                }
              }
            }
          }
          EOF

          # Проверяем результат
          echo "Created file content:" >&2
          cat /run/onlyoffice/config/local.json >&2
        '';
      in {
        serviceConfig = {
          ExecStartPre = [createLocalDotJson];
          # Важно: убедитесь, что у сервиса есть права на чтение секрета
          SupplementaryGroups = ["keys"];
        };
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
