{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jellyfinctl;
in {
  options.services.jellyfinctl = {
    enable = lib.mkEnableOption {
      description = "Enable Jellyfin";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    services.jellyfin = {
      enable = true;
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "jellyfin.${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8096"; # порт Jellyfin по умолчанию
            proxyWebsockets = true; # для поддержки WebSocket (Jellyfin использует их)
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
