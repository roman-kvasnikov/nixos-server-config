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

  tubearchivistRedisConfig = config.services.redis.servers.tubearchivist;
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
      default = 8000;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Tubearchivist";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Tubearchivist";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
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
      users.users.tubearchivist = {
        isSystemUser = true;
        uid = 985;
        group = cfgHomelab.systemGroup;
      };

      virtualisation.oci-containers.backend = "podman";
      virtualisation.oci-containers.containers.tubearchivist = {
        image = "bbilly1/tubearchivist:v0.5.0";
        environment = {
          ES_URL = "http://127.0.0.1:9200";
          REDIS_CON = "redis://${tubearchivistRedisConfig.bind}:${builtins.toString tubearchivistRedisConfig.port}";
          HOST_UID = "${builtins.toString config.users.users.tubearchivist.uid}";
          HOST_GID = "${builtins.toString config.users.groups.${cfgHomelab.systemGroup}.gid}";
          TA_USERNAME = "tubearchivist";
          TA_PASSWORD = "verysecret";
          ELASTIC_PASSWORD = "verysecret";
          TA_HOST = "https://${cfg.domain}";
          TZ = config.time.timeZone;
        };
        volumes = [
          "/data/media/YouTube:/youtube"
          "/var/cache/tubearchivist:/cache"
        ];
        extraOptions = ["--network=host"];
        # ports = [ "${builtins.toString port}:8000" ];
      };
      networking.firewall.allowedTCPPorts = [8000];

      # need elastic api reporting v8
      virtualisation.oci-containers.containers.tubearchivist-es = {
        image = "bbilly1/tubearchivist-es";
        environment = {
          ELASTIC_PASSWORD = "verysecret";
          ES_JAVA_OPTS = "-Xms1g -Xmx1g";
          "xpack.security.enabled" = "true";
          "discovery.type" = "single-node";
          "path.repo" = "/usr/share/elasticsearch/data/snapshot";
        };
        volumes = ["/var/lib/tubearchivist/elasticsearch:/usr/share/elasticsearch/data"];
        ports = ["9200:9200"];
      };

      services.redis.servers.tubearchivist.enable = true;
      services.redis.servers.tubearchivist.port = 6379;
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
