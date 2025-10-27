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

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Frigate module";
      default = "frigate.${cfgHomelab.domain}";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate data and recordings";
      default = "/var/lib/frigate";
    };

    cameras = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable camera";

          streamUrl = lib.mkOption {
            type = lib.types.str;
            example = "rtsp://user:pass@192.168.1.100:554/stream1";
            description = "RTSP stream URL for the camera";
          };

          recordEnabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable recording";
          };

          detectResolution = lib.mkOption {
            type = lib.types.submodule {
              options = {
                width = lib.mkOption {
                  type = lib.types.int;
                  default = 1920;
                  description = "Detection resolution width";
                };
                height = lib.mkOption {
                  type = lib.types.int;
                  default = 1080;
                  description = "Detection resolution height";
                };
              };
            };
            description = "Detection resolution for the camera";
          };

          snapshotsEnabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable snapshots";
          };

          motionMask = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Motion mask coordinates";
          };
        };
      });

      default = {};
      description = "Set of camera configurations by name";
    };

    recording = {
      enable = lib.mkEnableOption "Enable recording";

      retainDays = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Days to retain recordings";
      };

      events = {
        retainDays = lib.mkOption {
          type = lib.types.int;
          default = 14;
          description = "Days to retain event recordings";
        };

        preCapture = lib.mkOption {
          type = lib.types.int;
          default = 5;
          description = "Seconds to record before event";
        };

        postCapture = lib.mkOption {
          type = lib.types.int;
          default = 5;
          description = "Seconds to record after event";
        };
      };
    };

    detection = {
      enable = lib.mkEnableOption "Enable object detection";

      fps = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Detection FPS";
      };

      objects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["person" "cat" "dog"];
        description = "Objects to detect";
      };

      coralDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Coral TPU device (usb, pci, cpu)";
      };
    };

    snapshots = {
      enable = lib.mkEnableOption "Enable snapshots";

      retainDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Days to retain snapshots";
      };
    };

    mqtt = {
      enable = lib.mkEnableOption "Enable MQTT integration";

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "MQTT broker host";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 1883;
        description = "MQTT broker port";
      };

      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MQTT username";
      };

      password = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MQTT password";
      };
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
          url = "https://${cfg.host}";
          enableRecentEvents = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        frigate
        ffmpeg-full
      ];

      # systemd.tmpfiles.rules = [
      #   "d ${cfg.homeDir} 0750 frigate frigate - -"
      #   "d ${cfg.homeDir}/recordings 0750 frigate frigate - -"
      #   "d ${cfg.homeDir}/clips 0750 frigate frigate - -"
      #   "d ${cfg.homeDir}/snapshots 0750 frigate frigate - -"
      #   "d ${cfg.homeDir}/exports 0750 frigate frigate - -"
      #   "d ${cfg.homeDir}/db 0750 frigate frigate - -"
      # ];

      services.frigate = {
        enable = true;

        hostname = "127.0.0.1";

        vaapiDriver = "nvidia";

        checkConfig = true;

        settings = {
          cameras = lib.filterAttrs (_: cam: cam != null) (
            lib.mapAttrs (
              name: cfgCamera:
                lib.mkIf cfgCamera.enable {
                  ffmpeg.inputs = [
                    {
                      path = cfgCamera.streamUrl;
                      roles = ["detect"] ++ (lib.optional cfgCamera.recordEnabled "record");
                    }
                  ];

                  record.enabled = cfgCamera.recordEnabled;

                  detect = {
                    enabled = cfg.detection.enable;

                    width = cfgCamera.detectResolution.width or 1920;
                    height = cfgCamera.detectResolution.height or 1080;
                    fps = cfg.detection.fps;
                  };

                  snapshots.enabled = cfgCamera.snapshotsEnabled;

                  motion = lib.mkIf (cfgCamera.motionMask != null) {
                    mask = cfgCamera.motionMask;
                  };
                }
            )
            cfg.cameras
          );

          record = {
            enabled = true;

            retain = {
              days = cfg.recording.retainDays;
              mode = "all";
            };
          };

          detectors = lib.mkMerge [
            (lib.mkIf (cfg.detection.coralDevice != null) {
              coral = {
                type = "edgetpu";
                device = cfg.detection.coralDevice;
              };
            })
            (lib.mkIf (cfg.detection.coralDevice == null) {
              cpu = {
                type = "cpu";
              };
            })
          ];

          model = {
            width = 320;
            height = 320;
            labelmap_path = null;
          };

          objects = {
            track = cfg.detection.objects;
            filters = {};
          };

          snapshots = {
            enabled = cfg.snapshots.enable;

            retain = {
              default = cfg.snapshots.retainDays;
            };
          };

          database = {
            path = "${cfg.homeDir}/db/frigate.db";
          };

          ui = {
            timezone = config.time.timeZone;
          };

          live = {
            height = 720;
            quality = 8;
          };

          go2rtc.streams = lib.filterAttrs (_: stream: stream != null) (
            lib.mapAttrs (
              name: cfgCamera:
                lib.mkIf cfgCamera.enable [cfgCamera.streamUrl]
            )
            cfg.cameras
          );

          birdseye = {
            enabled = true;

            width = 1920;
            height = 1080;
            quality = 8;
            mode = "continuous";
            # "objects"	Только если найден объект (по умолчанию — лучшее сочетание нагрузки и пользы)
            # "motion"	Показывает камеры при движении
            # "continuous"	Показывает всегда все камеры (может нагружать систему)
            # "off"	Полностью отключает Birdseye
          };

          mqtt = lib.mkIf cfg.mqtt.enable {
            enabled = false;

            host = cfg.mqtt.host;
            port = cfg.mqtt.port;
            user = cfg.mqtt.user;
            password = cfg.mqtt.password;
          };

          logger = {
            default = "info";
          };

          environment_vars = {};
        };
      };

      systemd.services.frigate = {
        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "10s";

          # Device access for Coral TPU
          PrivilegeEscalation = true;
          SupplementaryGroups = ["video"];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      networking.firewall.allowedTCPPorts = [8971];

      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;

            locations."/" = {
              # proxyPass = "http://127.0.0.1:5000";
              proxyPass = "http://127.0.0.1:8971";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_buffering off;
                proxy_cache off;
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout 600s;

                # For large video uploads
                client_max_body_size 5000M;

                # Security headers
                add_header X-Frame-Options "SAMEORIGIN" always;
                add_header X-Content-Type-Options "nosniff" always;
                add_header X-XSS-Protection "1; mode=block" always;
              '';
            };

            # WebSocket support for live view
            locations."/ws" = {
              # proxyPass = "http://127.0.0.1:5000/ws";
              proxyPass = "http://127.0.0.1:8971/ws";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_buffering off;
                proxy_cache off;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
            };

            # API endpoint
            locations."/api" = {
              # proxyPass = "http://127.0.0.1:5000/api";
              proxyPass = "http://127.0.0.1:8971/api";
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_buffering off;
                client_max_body_size 100M;
              '';
            };
          };
        };
      };
    })
  ];
}
