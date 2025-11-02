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

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to qBittorrent.";
      default = true;
    };

    torrentsDir = lib.mkOption {
      type = lib.types.path;
      description = "Torrents directory for qBittorrent";
      default = "/data/.torrents";
    };

    downloadsDir = lib.mkOption {
      type = lib.types.path;
      description = "Downloads directory for qBittorrent";
      default = "/data/Downloads";
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
        "d ${cfg.torrentsDir} 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.downloadsDir} 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
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
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              deny all;
            '';

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                client_max_body_size 100M;
              '';
            };
          };
        };
      };
    })
  ];
}
