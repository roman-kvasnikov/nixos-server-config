{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.linkwardenctl;
in {
  options.homelab.services.linkwardenctl = {
    enable = lib.mkEnableOption "Enable Linkwarden";

    domain = lib.mkOption {
      description = "Domain of the Linkwarden module";
      type = lib.types.str;
      default = "linkwarden.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Linkwarden module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Linkwarden module";
      type = lib.types.port;
      default = 3000;
    };

    dataDir = lib.mkOption {
      description = "Data directory of the Linkwarden module";
      type = lib.types.str;
      default = "/mnt/data/AppData/Linkwarden";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Linkwarden";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Linkwarden";
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
        default = "Linkwarden";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Bookmarks manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "linkwarden.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "linkwarden";
          url = "https://${cfg.domain}";
          key = "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..vRs-Sp316tAQfnNk.rtzy2uF73nQg9JmTnLXCZRdN1FfRK1gpCOvRuTAiADQ1jmuQuzOuiymmwad271iGilGaa9EWYomJ90rVzGHTCfAu2IqW-uVeFsotl0XJd2LS2MUaIwVE.-mRfCPTjY36-hekejEUcCg";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        linkwarden = {
          enable = true;

          host = cfg.host;
          port = cfg.port;

          openFirewall = !cfgNginx.enable;

          storageLocation = cfg.dataDir;

          database = {
            host = "/run/pgbouncer";
            port = "6432";
            name = "linkwarden";
            user = "linkwarden";
          };

          enableRegistration = true;

          environmentFile = config.age.secrets.linkwarden-env.path;
        };

        postgresql = {
          identMap = lib.mkAfter ''
            pgbouncer pgbouncer  linkwarden
            pgbouncer linkwarden linkwarden
          '';
        };

        pgbouncer.settings = {
          databases = {
            linkwarden = "host=/run/postgresql port=5432 dbname=linkwarden";
          };
        };
      };

      age.secrets.linkwarden-env = {
        file = ../../../secrets/linkwarden.env.age;
        owner = "linkwarden";
        group = "linkwarden";
        mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.linkwarden = {
          database = "linkwarden";
          paths = [config.services.linkwarden.storageLocation];
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
