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
      environment.systemPackages = with pkgs; [
        frigate
        ffmpeg-full
        cudaPackages.cudatoolkit
        cudaPackages.tensorrt
        cudaPackages.cudnn
        nvidia-container-toolkit
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
          auth = {
            enabled = false;
            reset_admin_password = true;
          };

          cameras = lib.filterAttrs (_: cam: cam != null) (
            lib.mapAttrs (
              name: cfgCamera:
                lib.mkIf cfgCamera.enable {
                  ffmpeg.inputs = [
                    {
                      path = cfgCamera.streamUrl;
                      roles = cfgCamera.roles;
                    }
                  ];

                  detect = {
                    enabled = cfgCamera.detect.enable;

                    width = cfgCamera.detect.width;
                    height = cfgCamera.detect.height;
                    fps = cfgCamera.detect.fps;
                  };

                  record = {
                    enabled = cfgCamera.record.enable;

                    retain = {
                      days = cfgCamera.record.retain.days;
                      mode = cfgCamera.record.retain.mode;
                    };
                  };

                  audio = {
                    enabled = cfgCamera.audio.enable;
                  };

                  snapshots = {
                    enabled = cfgCamera.snapshots.enable;

                    retain = {
                      default = cfgCamera.snapshots.retain.default;
                    };
                  };

                  motion = {
                    enabled = cfgCamera.motion.enable;

                    mask = lib.mkIf (cfgCamera.motion.mask != null) cfgCamera.motion.mask;
                  };

                  onvif = lib.mkIf cfgCamera.onvif.enable {
                    host = cfgCamera.onvif.host;
                    port = cfgCamera.onvif.port;
                    user = cfgCamera.onvif.user;
                    password = cfgCamera.onvif.password;
                  };
                }
            )
            cfg.cameras
          );

          detectors = {
            nvidia = {
              # type = "nvidia";
              type = "tensorrt";
              device = 0;
            };
          };

          ui = {
            timezone = config.time.timeZone;
          };
        };
      };

      systemd.services.frigate.environment.LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.tensorrt
        pkgs.cudaPackages.cudnn
      ];
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
