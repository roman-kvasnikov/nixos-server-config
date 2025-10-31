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

    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Data directory for qBittorrent";
      default = "/data/qbittorrent";
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

        profileDir = cfg.dataDir;
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
              proxyPass = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_set_header   Host               $proxy_host;
                proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Host   $http_host;
                proxy_set_header   X-Forwarded-Proto  $scheme;

                client_max_body_size  100M;
              '';
            };
          };
        };
      };
    })
  ];
}
