{
  config,
  lib,
  pkgs,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  users.users.tubearchivist = {
    isSystemUser = true;
    group = cfgHomelab.systemGroup;
  };

  networking.firewall.allowedTCPPorts = [12345];

  virtualisation.oci-containers.containers = {
    # База данных (запускается первой)
    tubearchivist = {
      image = "bbilly1/tubearchivist";
      # autoStart = true;
      ports = ["12345:8000"];
      volumes = [
        "/data/media/YouTube:/youtube"
        "/var/cache/tubearchivist:/cache"
      ];
      environment = {
        ES_URL = "http://127.0.0.1:9200";
        REDIS_CON = "redis://archivist-redis:6381";
        HOST_UID = "${toString config.users.users.tubearchivist.uid}";
        HOST_GID = "${toString config.users.groups.${cfgHomelab.systemGroup}.gid}";
        TA_HOST = "http://127.0.0.1:12345";
        TA_USERNAME = "tubearchivist";
        TA_PASSWORD = "verysecret";
        ELASTIC_PASSWORD = "verysecret";
        TZ = config.time.timeZone;
      };
      extraOptions = [
        "--health-cmd='curl -f http://127.0.0.1:12345/api/health/'"
        "--health-interval=2m"
        "--health-retries=3"
        "--health-start-period=30s"
        "--health-timeout=10s"
      ];
      dependsOn = ["archivist-es" "archivist-redis"];
    };

    archivist-redis = {
      image = "redis";
      # autoStart = true;
      ports = ["6381:6379"];
      volumes = [
        "/redis:/data"
      ];
      dependsOn = ["archivist-es"];
    };

    archivist-es = {
      image = "bbilly1/tubearchivist-es";
      # autoStart = true;
      volumes = [
        "/var/lib/tubearchivist/elasticsearch:/usr/share/elasticsearch/data"
      ];
      ports = ["9200:9200"];
      environment = {
        ELASTIC_PASSWORD = "verysecret";
        ES_JAVA_OPTS = "-Xms1g -Xmx1g";
        "xpack.security.enabled" = "true";
        "discovery.type" = "single-node";
        "path.repo" = "/usr/share/elasticsearch/data/snapshot";
      };
    };
  };
}
