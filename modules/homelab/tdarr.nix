{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.tdarrctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.tdarrctl = {
    enable = lib.mkEnableOption "Enable Tdarr";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for the Tdarr service";
      default = "tdarr.${cfgServer.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Tdarr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Media transcoding manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "tdarr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "tdarr";
          url = "https://${cfg.host}";
          key = "123456";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.docker.enable = true;

      virtualisation.oci-containers.containers.tdarr = {
        image = "ghcr.io/haveagitgat/tdarr:latest";
        autoStart = true;
        ports = [
          "8266:8266" # Tdarr server port
          "8265:8265" # Web UI port (you can change external 10000 if needed)
        ];
        volumes = [
          "/var/lib/tdarr/server:/app/server"
          "/var/lib/tdarr/configs:/app/configs"
          "/var/lib/tdarr/logs:/app/logs"
          "/media:/media"
          "/transcode_cache:/temp"
        ];
        devices = [
          "/dev/dri:/dev/dri"
        ];
        environment = {
          TZ = "Europe/Moscow";
          PUID = "1000";
          PGID = "1000";
          UMASK_SET = "002";
          serverIP = "0.0.0.0";
          serverPort = "8266";
          webUIPort = "8265";
          internalNode = "true";
          inContainer = "true";
          ffmpegVersion = "7";
          nodeName = "InternalNode";
          auth = "false";
          openBrowser = "true";
          maxLogSizeMB = "10";
          cronPluginUpdate = "";
        };
      };

      users.users.tdarr = {
        isSystemUser = true;
        group = cfgServer.systemGroup;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx.virtualHosts.${cfg.host} = {
        enableACME = cfgAcme.enable;
        forceSSL = cfgAcme.enable;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8265";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 100M;
            proxy_http_version 1.1;
            proxy_buffering off;
            proxy_read_timeout   300s;
            proxy_send_timeout   300s;
            send_timeout         300s;
          '';
        };
      };
    })
  ];
}
