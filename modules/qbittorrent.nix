{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.qbittorrentctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.qbittorrentctl = {
    enable = lib.mkEnableOption {
      description = "Enable qBittorrent";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.qbittorrent = {
      enable = true;

      user = "media";
      group = "media";
    };

    users.users.media = {
      isSystemUser = true;

      group = "media";
    };

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
