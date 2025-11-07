{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.vaultwardenctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.vaultwardenctl = {
    enable = lib.mkEnableOption "Enable Vaultwarden";

    domain = lib.mkOption {
      description = "Domain of the Vaultwarden module";
      type = lib.types.str;
      default = "vaultwarden.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Vaultwarden module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Vaultwarden module";
      type = lib.types.port;
      default = 8222;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Vaultwarden";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Vaultwarden";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Vaultwarden";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Password manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "bitwarden.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.postgresql = {
        enable = true;

        ensureUsers = [
          {
            name = "vaultwarden";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = ["vaultwarden"];
      };

      services.vaultwarden = {
        enable = true;

        dbBackend = "postgresql";

        config = {
          DOMAIN = "https://${cfg.domain}";
          SIGNUPS_ALLOWED = false;
          WEBSOCKET_ENABLED = true;
          TZ = config.time.timeZone;

          ROCKET_ADDRESS = cfg.host;
          ROCKET_PORT = cfg.port;
          ROCKET_LOG = "critical";

          DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
        };

        environmentFile = config.age.secrets.vaultwarden-env.path;
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.vaultwarden = {
          database = "vaultwarden";
          paths = ["/var/lib/vaultwarden"];
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
            };
          };
        };
      };
    })
  ];
}
