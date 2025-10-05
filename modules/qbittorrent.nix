{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.qbittorrentctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;

  user = "qbittorrent";
  group = "media";
in {
  options.services.qbittorrentctl = {
    enable = lib.mkEnableOption {
      description = "Enable qBittorrent";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qbittorrent
    ];

    services.qbittorrent = {
      enable = true;

      # user = user;
      # group = group;

      profileDir = "/home/qBittorrent";
    };

    # systemd.tmpfiles.rules = [
    #   "d /home/qbittorrent 0750 ${user} ${group} - -"
    # ];

    # users = {
    #   users.${user} = {
    #     isSystemUser = true;
    #     group = group;
    #   };

    #   groups.${group} = {};
    # };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "torrent.${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080"; # Проксируем на qBittorrent
            proxyWebsockets = true; # Поддержка WebSocket (если используется)
            recommendedProxySettings = true; # Рекомендуемые настройки прокси
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
          };
        };
      };
    };
  };
}
