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
    enable = lib.mkEnableOption "Enable qBittorrent";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the qBittorrent module";
      default = "torrent.${config.server.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qbittorrent
    ];

    services.qbittorrent = {
      enable = true;

      user = config.server.systemUser;
      group = config.server.systemGroup;
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.host}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            proxyWebsockets = true;
            recommendedProxySettings = true;
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
