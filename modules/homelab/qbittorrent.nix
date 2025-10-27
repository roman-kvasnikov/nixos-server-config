{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.qbittorrentctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.qbittorrentctl = {
    enable = lib.mkEnableOption "Enable qBittorrent";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the qBittorrent module";
      default = "torrent.${cfgHomelab.domain}";
    };

    initialDirectory = lib.mkOption {
      type = lib.types.path;
      description = "Initial directory for qBittorrent";
      default = "/";
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
        default = "Services";
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

      systemd.tmpfiles.rules = [
        "d ${cfg.initialDirectory}/.torrents 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.initialDirectory}/Downloads 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.initialDirectory}/media 0755 root root - -"
        "d ${cfg.initialDirectory}/media/Movies 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.initialDirectory}/media/TV\ Shows 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.initialDirectory}/media/Cartoons 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
      ];

      services.qbittorrent = {
        enable = true;

        user = "qbittorrent";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;
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
