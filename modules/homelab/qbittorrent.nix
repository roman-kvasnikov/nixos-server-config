{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.qbittorrentctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.qbittorrentctl = {
    enable = lib.mkEnableOption "Enable qBittorrent";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the qBittorrent module";
      default = "torrent.${cfgServer.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "qBittorrent";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Torrent client";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "qbittorrent.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Downloads";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "qbittorrent";
          url = "https://${cfg.host}";
          username = "admin";
          password = "123456";
          enableLeechProgress = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        qbittorrent
      ];

      services.qbittorrent = {
        enable = true;

        user = "qbittorrent";
        group = cfgServer.systemGroup;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
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
    })
  ];
}
