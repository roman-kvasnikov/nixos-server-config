{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.frigatectl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.frigatectl = {
    enable = lib.mkEnableOption "Enable Frigate NVR";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Frigate module";
      default = "frigate.${cfgServer.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate data and recordings";
      default = "/var/lib/frigate";
    };

    # Camera 1 configuration
    camera1 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable first camera";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "camera1";
        description = "Name of the first camera";
      };

      streamUrl = lib.mkOption {
        type = lib.types.str;
        example = "rtsp://user:pass@192.168.1.100:554/stream1";
        description = "RTSP stream URL for the first camera";
      };

      detectResolution = lib.mkOption {
        type = lib.types.attrs;
        default = {
          width = 1920;
          height = 1080;
        };
        description = "Detection resolution for the first camera";
      };

      recordEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable recording for the first camera";
      };

      snapshotsEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable snapshots for the first camera";
      };

      motionMask = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = ["0,0,300,0,300,200,0,200"];
        description = "Motion mask coordinates for the first camera";
      };
    };

    # Camera 2 configuration
    camera2 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable second camera";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "camera2";
        description = "Name of the second camera";
      };

      streamUrl = lib.mkOption {
        type = lib.types.str;
        example = "rtsp://user:pass@192.168.1.101:554/stream1";
        description = "RTSP stream URL for the second camera";
      };

      detectResolution = lib.mkOption {
        type = lib.types.attrs;
        default = {
          width = 1920;
          height = 1080;
        };
        description = "Detection resolution for the second camera";
      };

      recordEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable recording for the second camera";
      };

      snapshotsEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable snapshots for the second camera";
      };

      motionMask = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = ["0,0,300,0,300,200,0,200"];
        description = "Motion mask coordinates for the second camera";
      };
    };

    # Detection settings
    detection = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
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
        default = true;
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
        ffmpeg-full
        frigate
      ];

      # users.users.frigate = {
      #   isSystemUser = true;
      #   group = cfgServer.systemGroup;
      #   extraGroups = ["video"];
      # };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 frigate frigate - -"
        "d ${cfg.dataDir}/recordings 0750 frigate frigate - -"
        "d ${cfg.dataDir}/clips 0750 frigate frigate - -"
        "d ${cfg.dataDir}/snapshots 0750 frigate frigate - -"
        "d ${cfg.dataDir}/exports 0750 frigate frigate - -"
        "d ${cfg.dataDir}/db 0750 frigate frigate - -"
      ];

      services.frigate = {
        enable = true;

        hostname = "127.0.0.1";
        # port = 5000;

        settings = {
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
            path = "${cfg.dataDir}/db/frigate.db";
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

          # Cameras configuration
          cameras = lib.mkMerge [
            (lib.mkIf cfg.camera1.enable {
              "${cfg.camera1.name}" = {
                ffmpeg = {
                  inputs = [
                    {
                      path = cfg.camera1.streamUrl;
                      roles =
                        ["detect"]
                        ++ (lib.optional cfg.camera1.recordEnabled "record");
                    }
                  ];
                };

                detect = {
                  enabled = cfg.detection.enabled;
                  width = cfg.camera1.detectResolution.width;
                  height = cfg.camera1.detectResolution.height;
                  fps = cfg.detection.fps;
                };

                record = {
                  enabled = cfg.camera1.recordEnabled;
                };

                snapshots = {
                  enabled = cfg.camera1.snapshotsEnabled;
                };

                motion = lib.mkIf (cfg.camera1.motionMask != null) {
                  mask = cfg.camera1.motionMask;
                };
              };
            })

            (lib.mkIf cfg.camera2.enable {
              "${cfg.camera2.name}" = {
                ffmpeg = {
                  inputs = [
                    {
                      path = cfg.camera2.streamUrl;
                      roles =
                        ["detect"]
                        ++ (lib.optional cfg.camera2.recordEnabled "record");
                    }
                  ];
                };

                detect = {
                  enabled = cfg.detection.enabled;
                  width = cfg.camera2.detectResolution.width;
                  height = cfg.camera2.detectResolution.height;
                  fps = cfg.detection.fps;
                };

                record = {
                  enabled = cfg.camera2.recordEnabled;
                };

                snapshots = {
                  enabled = cfg.camera2.snapshotsEnabled;
                };

                motion = lib.mkIf (cfg.camera2.motionMask != null) {
                  mask = cfg.camera2.motionMask;
                };
              };
            })
          ];

          # UI configuration
          ui = {
            timezone = "Europe/Vienna";
          };

          # Live configuration
          live = {
            height = 720;
            quality = 8;
          };

          # Go2RTC configuration for WebRTC streaming
          go2rtc = {
            streams = lib.mkMerge [
              (lib.mkIf cfg.camera1.enable {
                "${cfg.camera1.name}" = [
                  cfg.camera1.streamUrl
                ];
              })
              (lib.mkIf cfg.camera2.enable {
                "${cfg.camera2.name}" = [
                  cfg.camera2.streamUrl
                ];
              })
            ];
          };

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
          # User = "frigate";
          # Group = cfgServer.systemGroup;
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
