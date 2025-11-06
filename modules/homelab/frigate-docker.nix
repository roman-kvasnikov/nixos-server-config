{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.frigatectl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.frigatectl = {
    enable = lib.mkEnableOption "Enable Frigate NVR";

    domain = lib.mkOption {
      description = "Domain of the Frigate NVR module";
      type = lib.types.str;
      default = "frigate.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Frigate NVR module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Frigate NVR module";
      type = lib.types.port;
      default = 5000;
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate data and recordings";
      default = "/var/lib/frigate";
    };

    cameras = lib.mkOption {
      description = "Set of camera configurations by name";

      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable camera";

          streamUrl = lib.mkOption {
            description = "RTSP stream URL for the camera";
            type = lib.types.str;
            example = "rtsp://user:pass@192.168.1.100:554/stream1";
          };

          roles = lib.mkOption {
            description = "List of camera roles";
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["detect" "record" "audio"];
          };

          detect = {
            enable = lib.mkEnableOption "Enable detection";

            width = lib.mkOption {
              description = "Detection resolution width";
              type = lib.types.int;
              default = 1920;
            };
            height = lib.mkOption {
              description = "Detection resolution height";
              type = lib.types.int;
              default = 1080;
            };
            fps = lib.mkOption {
              description = "Detection FPS";
              type = lib.types.int;
              default = 5;
            };
          };

          record = {
            enable = lib.mkEnableOption "Enable recording";

            retain = {
              days = lib.mkOption {
                description = "Days to retain recordings";
                type = lib.types.int;
                default = 10;
              };

              mode = lib.mkOption {
                description = "Days to retain recordings";
                type = lib.types.str;
                default = "all";
              };
            };
          };

          audio = {
            enable = lib.mkEnableOption "Enable snapshots";
          };

          snapshots = {
            enable = lib.mkEnableOption "Enable snapshots";

            retain = {
              default = lib.mkOption {
                description = "Days to retain snapshots";
                type = lib.types.int;
                default = 10;
              };
            };
          };

          motion = {
            enable = lib.mkEnableOption "Enable snapshots";

            mask = lib.mkOption {
              description = "Motion mask coordinates";
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
            };
          };

          onvif = {
            enable = lib.mkEnableOption "Enable ONVIF camera";

            host = lib.mkOption {
              description = "Host of the ONVIF camera";
              type = lib.types.str;
              default = "";
            };
            port = lib.mkOption {
              description = "Port of the ONVIF camera";
              type = lib.types.port;
              default = 0;
            };
            user = lib.mkOption {
              description = "User of the ONVIF camera";
              type = lib.types.str;
              default = "";
            };
            password = lib.mkOption {
              description = "Password of the ONVIF camera";
              type = lib.types.str;
              default = "";
            };
          };
        };
      });

      default = {};
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Frigate";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "NVR with AI object detection";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "frigate.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "frigate";
          url = "https://${cfg.domain}";
          enableRecentEvents = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [8971 8554 8555];
      networking.firewall.allowedUDPPorts = [8555];

      virtualisation.oci-containers.backend = lib.mkDefault "podman";

      virtualisation.oci-containers.containers.frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        autoStart = true;

        # Привилегии контейнера
        privileged = true;

        # Порты
        ports = [
          "8971:8971"
          "8554:8554"
          "8555:8555/tcp"
          "8555:8555/udp"
        ];

        # Окружение
        environment = {
          FRIGATE_RTSP_PASSWORD = "password";
          FRIGATE_TZ = config.time.timeZone;
        };

        # Примонтированные тома
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/var/lib/frigate:/config:rw"
          "/var/lib/frigate/recordings:/media/frigate:rw"
        ];

        # Устройства
        devices = [
          "/dev/dri/renderD128:/dev/dri/renderD128"
          "/dev/dri/renderD129:/dev/dri/renderD129"
        ];

        # Дополнительно
        # stopTimeout = 30; # аналог stop_grace_period: 30s
        # shmSize = "512m"; # аналог shm_size
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

            locations."/" = {
              proxyPass = "http://127.0.0.1:8971";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
