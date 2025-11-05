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

          onvif = lib.mkOption {
            description = "Configuration of the ONVIF camera";
            type = lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "Enable ONVIF camera";

                host = lib.mkOption {
                  description = "Host of the ONVIF camera";
                  type = lib.types.str;
                };
                port = lib.mkOption {
                  description = "Port of the ONVIF camera";
                  type = lib.types.int;
                };
                user = lib.mkOption {
                  description = "User of the ONVIF camera";
                  type = lib.types.str;
                };
                password = lib.mkOption {
                  description = "Password of the ONVIF camera";
                  type = lib.types.str;
                };
              };
            };
          };

          recordEnabled = lib.mkOption {
            description = "Enable recording";
            type = lib.types.bool;
            default = false;
          };

          detectResolution = lib.mkOption {
            description = "Detection resolution for the camera";
            type = lib.types.submodule {
              options = {
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
              };
            };
          };

          audioEnabled = lib.mkOption {
            description = "Enable audio";
            type = lib.types.bool;
            default = false;
          };

          snapshotsEnabled = lib.mkOption {
            description = "Enable snapshots";
            type = lib.types.bool;
            default = false;
          };

          motionMask = lib.mkOption {
            description = "Motion mask coordinates";
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
          };
        };
      });

      default = {};
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
      environment.systemPackages = with pkgs; [
        frigate
        ffmpeg-full
      ];

      systemd.tmpfiles.rules = [
        "d /dev/shm/logs 0755 frigate frigate - -"
        "d /dev/shm/logs/frigate 0755 frigate frigate - -"
        "d /dev/shm/logs/go2rtc 0755 frigate frigate - -"
        "d /dev/shm/logs/nginx 0755 frigate frigate - -"

        "z /dev/shm/logs/frigate/current 0644 frigate frigate - -"
        "z /dev/shm/logs/go2rtc/current 0644 frigate frigate - -"
        "z /dev/shm/logs/nginx/current 0644 frigate frigate - -"
      ];

      services.frigate = {
        enable = true;

        hostname = cfg.domain;

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
                      roles = ["detect"] ++ (lib.optional cfgCamera.recordEnabled "record") ++ (lib.optional cfgCamera.audioEnabled "audio");
                    }
                  ];

                  onvif = lib.mkIf cfgCamera.onvif.enable {
                    host = cfgCamera.onvif.host;
                    port = cfgCamera.onvif.port;
                    user = cfgCamera.onvif.user;
                    password = cfgCamera.onvif.password;
                  };

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

          database = {
            path = "${cfg.homeDir}/frigate.db";
          };

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

          ui = {
            timezone = config.time.timeZone;
            # time_format = "browser";
            # date_style = "full";
            # time_style = "medium";
            # strftime_fmt = "%Y/%m/%d %H:%M";
            # unit_system = "metric";
          };

          live = {
            height = 720;
            quality = 8;
          };

          go2rtc = {
            streams = lib.filterAttrs (_: stream: stream != null) (
              lib.mapAttrs (
                name: cfgCamera:
                  lib.mkIf cfgCamera.enable [
                    cfgCamera.streamUrl

                    "ffmpeg:${name}#video=h264#hardware"
                  ]
              )
              cfg.cameras
            );

            # Настройки WebRTC для браузеров
            webrtc = {
              candidates = ["192.168.1.11:8555"]; # замените на IP вашего сервера
            };
          };

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

          # mqtt = lib.mkIf cfg.mqtt.enable {
          #   enabled = true;

          #   host = cfg.mqtt.host;
          #   port = cfg.mqtt.port;
          #   user = cfg.mqtt.user;
          #   password = cfg.mqtt.password;
          # };

          logger = {
            default = "info";

            logs = {
              frigate = "info";
              go2rtc = "info";
              nginx = "warning";
            };
          };

          environment_vars = {};

          auth = {
            enabled = false;
            reset_admin_password = true;
          };
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
          };
        };
      };
    })
  ];
}
