{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.obsidianctl;
in {
  options.homelab.services.obsidianctl = {
    enable = lib.mkEnableOption "Enable Obsidian";

    domain = lib.mkOption {
      description = "Domain of the Obsidian module";
      type = lib.types.str;
      default = "obsidian.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Obsidian module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Obsidian module";
      type = lib.types.port;
      default = 8030;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Obsidian data";
      default = "/mnt/data/AppData/Obsidian";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Obsidian";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Obsidian";
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
        default = "Obsidian";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Personal knowledge base";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "obsidian.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        obsidian = {
          image = "ghcr.io/linuxserver/obsidian:latest";
          autoStart = true;
          ports = [
            "${toString cfg.port}:3000/tcp"
          ];
          volumes = [
            "${cfg.dataDir}/config:/config:rw"
          ];
          environment = {
            TZ = config.time.timeZone;
            PUID = 1000;
            PGID = 1000;
            CUSTOM_USER = cfgHomelab.adminUser;
            PASSWORD = "123";
          };
          extraOptions = [
            "--security-opt=no-new-privileges:false"
            "--security-opt=seccomp:unconfined"

            "--health-cmd='timeout 10s bash -c \":> /dev/tcp/127.0.0.1/${toString cfg.port}\" || exit 1'"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=3"
            "--health-start-period=90s"

            "--shm-size=512mb"
          ];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.obsidian = {
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
