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

    homeDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate data and recordings";
      default = "/var/lib/frigate";
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
        privileged = true;
        ports = [
          "8971:8971"
          "8554:8554"
          "8555:8555/tcp"
          "8555:8555/udp"
        ];
        environment = {
          FRIGATE_RTSP_PASSWORD = "password";
          FRIGATE_TZ = config.time.timeZone;
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${cfg.homeDir}:/config:rw"
          "${cfg.homeDir}/recordings:/media/frigate:rw"
          {
            hostPath = "/tmp";
            containerPath = "/tmp/cache";
            type = "tmpfs";
            tmpfsSize = "1000000000";
          }
        ];
        devices = [
          "/dev/dri/renderD128:/dev/dri/renderD128"
        ];

        # Вместо shmSize и stopTimeout:
        extraOptions = "--shm-size=512m --stop-timeout=30";
      };
    })
  ];
}
