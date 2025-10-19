# Пока что не работает. Вроде как нужно создать необходимые каталоги. Еще не пробовал но вроде бы возможно в этом дело.
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
        default = "tdarr.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      # widget = lib.mkOption {
      #   type = lib.types.attrs;
      #   default = {
      #     type = "tdarr";
      #     url = "https://${cfg.host}";
      #     key = "123456";
      #   };
      # };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.docker.enable = true;

      users = {
        users.tdarr = {
          isSystemUser = true;
          uid = 991;
          group = "tdarr";
          description = "Tdarr media transcoding service";
        };
        groups.tdarr = {
          gid = 991;
        };
      };

      virtualisation.oci-containers.containers.hello-test = {
        image = "hello-world";
        autoStart = false; # т.к. он завершится сразу
        restartPolicy = "no";
      };

      # systemd.tmpfiles.rules = [
      #   # Каталоги для Tdarr
      #   "d /var/lib/tdarr 0755 tdarr tdarr -"
      #   "d /var/lib/tdarr/server 0755 tdarr tdarr -"
      #   "d /var/lib/tdarr/configs 0755 tdarr tdarr -"
      #   "d /var/lib/tdarr/logs 0755 tdarr tdarr -"

      #   # Каталог для кэша транскодирования
      #   "d /transcode_cache 0755 tdarr tdarr -"

      #   # Каталог для медиа (если не монтируешь снаружи)
      #   "d /tdarr 0755 tdarr tdarr -"
      # ];

      # virtualisation.oci-containers.containers.tdarr = {
      #   image = "ghcr.io/haveagitgat/tdarr:latest";
      #   autoStart = true;
      #   ports = [
      #     "8265:8265" # Web UI port
      #     "8266:8266" # Tdarr server port
      #   ];
      #   volumes = [
      #     "/var/lib/tdarr/server:/app/server"
      #     "/var/lib/tdarr/configs:/app/configs"
      #     "/var/lib/tdarr/logs:/app/logs"
      #     "/transcode_cache:/temp"
      #     "/tdarr:/media"
      #   ];
      #   devices = [
      #     "/dev/dri:/dev/dri"
      #   ];
      #   environment = {
      #     TZ = "Europe/Moscow";
      #     PUID = "991";
      #     PGID = "991";
      #     UMASK_SET = "002";
      #     serverIP = "0.0.0.0";
      #     serverPort = "8266";
      #     webUIPort = "8265";
      #     internalNode = "true";
      #     inContainer = "true";
      #     ffmpegVersion = "7";
      #     nodeName = "InternalTdarrNode";
      #     auth = "false";
      #     openBrowser = "true";
      #     maxLogSizeMB = "10";
      #     cronPluginUpdate = "";
      #     # NVIDIA_DRIVER_CAPABILITIES = "all";
      #     # NVIDIA_VISIBLE_DEVICES = "all";
      #   };
      # };
    })

    # (lib.mkIf (cfg.enable && cfgAcme.enable) {
    #   security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    # })

    # (lib.mkIf (cfg.enable && cfgNginx.enable) {
    #   services.nginx.virtualHosts.${cfg.host} = {
    #     enableACME = cfgAcme.enable;
    #     forceSSL = cfgAcme.enable;
    #     locations."/" = {
    #       proxyPass = "http://127.0.0.1:8265";
    #       proxyWebsockets = true;
    #       recommendedProxySettings = true;
    #       extraConfig = ''
    #         client_max_body_size 100M;
    #         proxy_http_version 1.1;
    #         proxy_buffering off;
    #         proxy_read_timeout   300s;
    #         proxy_send_timeout   300s;
    #         send_timeout         300s;
    #       '';
    #     };
    #   };
    # })
  ];
}
