{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.tubearchivistctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.tubearchivistctl = {
    enable = lib.mkEnableOption "Enable Tubearchivist";

    domain = lib.mkOption {
      description = "Domain of the Tubearchivist module";
      type = lib.types.str;
      default = "tubearchivist.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Tubearchivist module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Tubearchivist module";
      type = lib.types.port;
      default = 8057;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Tubearchivist";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Tubearchivist";
      type = lib.types.bool;
      default = false;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Tubearchivist";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Tube search engine for your private videos";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "tubearchivist.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "tubearchivist";
          url = "https://${cfg.domain}";
          key = "verysecret";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # users.users.tubearchivist = {
      #   isSystemUser = true;
      #   group = cfgHomelab.systemGroup;
      # };

      # systemd.tmpfiles.rules = [
      #   "d /var/cache/tubearchivist 0755 tubearchivist tubearchivist - -"
      # ];

      virtualisation.oci-containers.containers = {
        tubearchivist = {
          image = "bbilly1/tubearchivist:latest";
          autoStart = true;
          ports = ["${toString cfg.port}:8080"];
          volumes = [
            "/data/media/YouTube:/youtube"
            "/var/cache/tubearchivist:/cache"
          ];
          environment = {
            ES_URL = "http://archivist-es:9200";
            REDIS_CON = "redis://archivist-redis:6379";
            HOST_UID = "1000";
            HOST_GID = "1000";
            TA_HOST = "${cfg.domain}";
            TA_USERNAME = "admin";
            TA_PASSWORD = "password";
            ELASTIC_PASSWORD = "verysecret";
            TZ = config.time.timeZone;
          };
          dependsOn = ["archivist-es" "archivist-redis"];
          # networks = ["tubearchivist-net"];
          extraOptions = ["--network=host"];
        };

        archivist-redis = {
          image = "redis/redis-stack-server";
          autoStart = true;
          ports = ["6379:6379"];
          volumes = ["/var/lib/redis-tubearchivist:/data"];
          dependsOn = ["archivist-es"];
          # networks = ["tubearchivist-net"];
          extraOptions = ["--network=host"];
        };

        archivist-es = {
          image = "bbilly1/tubearchivist-es";
          autoStart = true;
          ports = ["9200:9200"];
          volumes = ["/var/lib/tubearchivist/elasticsearch:/usr/share/elasticsearch/data"];
          environment = {
            ELASTIC_PASSWORD = "verysecret";
            ES_JAVA_OPTS = "-Xms1g -Xmx1g";
            "xpack.security.enabled" = "true";
            "discovery.type" = "single-node";
            "path.repo" = "/usr/share/elasticsearch/data/snapshot";
          };
          # networks = ["tubearchivist-net"];
          extraOptions = ["--network=host"];
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
