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
  cfg = config.homelab.services.vaultwardenctl;
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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Vaultwarden";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Passwords manager";
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
      services = {
        vaultwarden = {
          enable = true;

          dbBackend = "postgresql";

          config = {
            DOMAIN = "https://${cfg.domain}";
            SIGNUPS_ALLOWED = true;
            WEBSOCKET_ENABLED = true;
            TZ = config.time.timeZone;

            ROCKET_ADDRESS = cfg.host;
            ROCKET_PORT = cfg.port;
            ROCKET_LOG = "critical";

            # DATABASE_URL = lib.mkForce "postgresql:///vaultwarden?host=/run/pgbouncer&port=6432";
            DATABASE_URL = lib.mkForce "postgresql:///vaultwarden?host=127.0.0.1&port=6432";
          };

          environmentFile = config.age.secrets.vaultwarden-env.path;
        };

        postgresql = {
          enable = true;

          ensureUsers = [
            {
              name = "vaultwarden";
              ensureDBOwnership = true;
            }
          ];
          ensureDatabases = ["vaultwarden"];

          identMap = lib.mkAfter ''
            pgbouncer pgbouncer   vaultwarden
            pgbouncer vaultwarden vaultwarden
          '';
        };

        pgbouncer.settings = {
          databases = {
            vaultwarden = "host=127.0.0.1 port=5432 dbname=vaultwarden";
          };
        };

        fail2ban = {
          enable = true;

          jails.vaultwarden.settings = {
            enabled = true;

            backend = "systemd";
            port = "80,443";
            protocol = "tcp";
            filter = "vaultwarden[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
            maxretry = 3;
            bantime = 3600; # 1 hour
            findtime = 600; # 10 minutes
          };
        };
      };

      environment.etc."fail2ban/filter.d/vaultwarden.local".text = lib.mkDefault (lib.mkAfter ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*?Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
        ignoreregex =
      '');

      environment.etc."pgbouncer/userslist.txt".text = lib.mkAfter ''
        "vaultwarden" ""
      '';

      age.secrets.vaultwarden-env = {
        file = ../../../secrets/vaultwarden.env.age;
        owner = "vaultwarden";
        group = "vaultwarden";
        mode = "0400";
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

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

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
