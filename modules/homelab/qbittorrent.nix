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
      default = "/data/.torrents";
    };

    downloadsDir = lib.mkOption {
      description = "Downloads directory for qBittorrent";
      type = lib.types.path;
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

        webuiPort = cfg.port;

        openFirewall = !cfgNginx.enable;
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

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              deny all;
            '';

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
