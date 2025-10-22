{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.bluecherryctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.bluecherryctl = {
    enable = lib.mkEnableOption "Enable Bluecherry DVR via Docker";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Bluecherry module";
      default = "cameras.${cfgHomelab.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory for Bluecherry data (recordings, db, etc.)";
      default = "/var/lib/bluecherry";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Bluecherry DVR";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Camera surveillance";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "video-camera.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "bluecherry";
          url = "https://${cfg.host}";
          username = "admin";
          password = "admin";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.docker.enable = true;

      users.users.bluecherry = {
        isSystemUser = true;
        home = cfg.dataDir;
        group = "bluecherry";
      };

      users.groups.bluecherry = {};

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 bluecherry bluecherry - -"
      ];

      systemd.services.bluecherry-dvr = {
        description = "Bluecherry DVR via Docker";
        after = ["docker.service" "network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker}/bin/docker run --rm \
              --name bluecherry-dvr \
              --network host \
              -e TZ=Europe/Moscow \
              -v ${cfg.dataDir}:/var/lib/bluecherry \
              -v /etc/localtime:/etc/localtime:ro \
              bluecherry/bluecherry-server:latest
          '';
          ExecStop = "${pkgs.docker}/bin/docker stop bluecherry-dvr";
          Restart = "always";
          User = "bluecherry";
        };
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx.virtualHosts."${cfg.host}" = {
        enableACME = cfgAcme.enable;
        forceSSL = cfgAcme.enable;
        locations."/" = {
          proxyPass = "http://127.0.0.1:7001";
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
    })
  ];
}
