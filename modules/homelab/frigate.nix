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
      type = lib.types.listOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable camera";
          };

          name = lib.mkOption {
            type = lib.types.str;
            description = "Camera name (must be unique)";
          };

          streamUrl = lib.mkOption {
            type = lib.types.str;
            example = "rtsp://user:pass@192.168.1.100:554/stream1";
            description = "RTSP stream URL for the camera";
          };

          detectResolution = lib.mkOption {
            type = lib.types.attrs;
            default = {
              width = 1920;
              height = 1080;
            };
            description = "Detection resolution for the camera";
          };

          recordEnabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable recording";
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

      default = [];
      description = "List of camera configurations";
    };

    # Detection settings
    detection = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable object detection";
      };

      fps = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Detection FPS";
      };

      objects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["person" "car" "cat" "dog"];
        description = "Objects to detect";
      };

      coralDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "usb";
        description = "Coral TPU device (usb, pci, cpu)";
      };
    };

    # Recording settings
    recording = {
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
          default = 10;
          description = "Seconds to record after event";
        };
      };
    };

    # Snapshots settings
    snapshots = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable snapshots";
      };

      retainDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Days to retain snapshots";
      };
    };

    # MQTT settings
    mqtt = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable MQTT integration";
      };

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

    # Homepage integration
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

        settings = {
          cameras = builtins.listToAttrs (
            builtins.map (cam: {
              name = cam.name;
              value = {
                ffmpeg.inputs = [
                  {
                    path = cam.streamUrl;
                    roles = ["detect"] ++ (lib.optional cam.recordEnabled "record");
                  }
                ];

                detect = {
                  enabled = cfg.detection.enabled;
                  width = cam.detectResolution.width;
                  height = cam.detectResolution.height;
                  fps = cfg.detection.fps;
                };

                record.enabled = cam.recordEnabled;
                snapshots.enabled = cam.snapshotsEnabled;

                motion = lib.mkIf (cam.motionMask != null) {
                  mask = cam.motionMask;
                };
              };
            }) (lib.filter (cam: cam.enable) cfg.cameras)
          );

          # MQTT configuration
          mqtt = lib.mkIf cfg.mqtt.enabled {
            enabled = true;
            host = cfg.mqtt.host;
            port = cfg.mqtt.port;
            user = cfg.mqtt.user;
            password = cfg.mqtt.password;
          };

          # Database configuration
          database = {
            path = "${cfg.homeDir}/db/frigate.db";
          };

          # Detector configuration
          detectors =
            if cfg.detection.coralDevice != null
            then {
              coral = {
                type = "edgetpu";
                device = cfg.detection.coralDevice;
              };
            }
            else {
              cpu = {
                type = "cpu";
              };
            };

          # Model configuration
          model = {
            width = 320;
            height = 320;
            labelmap_path = null;
          };

          # Objects configuration
          objects = {
            track = cfg.detection.objects;
            filters = {};
          };

          # Recording configuration
          record = {
            enabled = true;
            retain = {
              days = cfg.recording.retainDays;
              mode = "all";
            };
          };

          # Snapshots configuration
          snapshots = {
            enabled = cfg.snapshots.enabled;
            retain = {
              default = cfg.snapshots.retainDays;
            };
          };

          # UI configuration
          ui = {
            timezone = "Europe/Moscow";
          };

          # Live configuration
          live = {
            height = 720;
            quality = 8;
          };

          # Go2RTC configuration for WebRTC streaming
          go2rtc.streams = builtins.listToAttrs (
            builtins.map (cam: {
              name = cam.name;
              value = [cam.streamUrl];
            }) (lib.filter (cam: cam.enable) cfg.cameras)
          );

          # Birdseye view configuration
          birdseye = {
            enabled = true;
            width = 1920;
            height = 1080;
            quality = 8;
            mode = "objects";
          };

          # Logger configuration
          logger = {
            default = "info";
          };

          # Environment vars
          environment_vars = {};
        };
      };

      # Systemd service overrides
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
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;

            locations."/" = {
              proxyPass = "http://127.0.0.1:5000";
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
              proxyPass = "http://127.0.0.1:5000/ws";
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
              proxyPass = "http://127.0.0.1:5000/api";
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
