{
  config,
  lib,
  pkgs,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.qbittorrentctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.qbittorrentctl = {
    enable = lib.mkEnableOption "Enable qBittorrent";

    domain = lib.mkOption {
      description = "Domain of the qBittorrent module";
      type = lib.types.str;
      default = "qbittorrent.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the qBittorrent module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the qBittorrent module";
      type = lib.types.port;
      default = 8080;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to qBittorrent";
      type = lib.types.bool;
      default = true;
    };

    torrentsDir = lib.mkOption {
      description = "Torrents directory for qBittorrent";
      type = lib.types.path;
      default = "/mnt/media/Torrents/.torrents";
    };

    downloadsDir = lib.mkOption {
      description = "Downloads directory for qBittorrent";
      type = lib.types.path;
      default = "/mnt/media/Torrents";
    };

    mediaFolders = lib.mkOption {
      description = "Media folders for qBittorrent";
      type = lib.types.listOf lib.types.str;
      default = ["Downloads" "Cartoons" "Movies" "Shows"];
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for qBittorrent";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
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
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "qbittorrent";
          url = "https://${cfg.domain}";
          username = "admin";
          password = "123456";
          enableLeechProgress = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.tmpfiles.rules =
        [
          "d ${cfg.downloadsDir} 2775 qbittorrent downloads - -"
          "d ${cfg.torrentsDir} 2775 qbittorrent downloads - -"
        ]
        ++ (lib.map (folder: "d ${cfg.downloadsDir}/${folder} 2775 qbittorrent downloads - -") cfg.mediaFolders);

      services.qbittorrent = {
        enable = true;

        webuiPort = cfg.port;

        openFirewall = !cfgNginx.enable;
      };

      users.users.qbittorrent = {
        extraGroups = ["downloads"];
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.qbittorrent = {
          paths = [config.services.qbittorrent.profileDir];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.domain}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
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
