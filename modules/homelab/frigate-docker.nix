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
      description = "Directory for Frigate config";
      default = "/var/lib/frigate";
    };

    storageDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate recordings and media";
      default = "/var/lib/frigate/storage";
    };

    tmpCacheSize = lib.mkOption {
      type = lib.types.str;
      description = "Size of tmpfs cache for recording segments";
      default = "1000000000";
    };

    shmSize = lib.mkOption {
      type = lib.types.str;
      description = "Shared memory size for frame processing";
      default = "512mb";
    };

    enableCoralUsb = lib.mkOption {
      type = lib.types.bool;
      description = "Enable USB Coral device passthrough";
      default = false;
    };

    enableCoralPcie = lib.mkOption {
      type = lib.types.bool;
      description = "Enable PCIe Coral device passthrough";
      default = false;
    };

    enableIntelHwAccel = lib.mkOption {
      type = lib.types.bool;
      description = "Enable Intel hardware acceleration";
      default = true;
    };

    enableRaspberryPi4 = lib.mkOption {
      type = lib.types.bool;
      description = "Enable Raspberry Pi 4 specific settings";
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Открываем порты согласно документации
      networking.firewall.allowedTCPPorts = [
        8971 # Authenticated UI and API
        8554 # RTSP restreaming
        8555 # WebRTC over TCP
      ];
      networking.firewall.allowedUDPPorts = [
        8555 # WebRTC over UDP
      ];

      # Создаём необходимые директории
      systemd.tmpfiles.rules = [
        "d '${cfg.homeDir}' 0755 root root - -"
        "d '${cfg.storageDir}' 0755 root root - -"
        "d '${cfg.storageDir}/clips' 0755 root root - -"
        "d '${cfg.storageDir}/recordings' 0755 root root - -"
        "d '${cfg.storageDir}/exports' 0755 root root - -"
      ];

      virtualisation.oci-containers.backend = lib.mkDefault "podman";

      virtualisation.oci-containers.containers.frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        autoStart = true;

        # Привилегированный режим рекомендован документацией
        privileged = true;

        ports = [
          "8971:8971" # UI and API
          # "5000:5000"        # Internal unauthenticated access - не выставляем по умолчанию
          "8554:8554" # RTSP feeds
          "8555:8555/tcp" # WebRTC over TCP
          "8555:8555/udp" # WebRTC over UDP
        ];

        environment = {
          FRIGATE_RTSP_PASSWORD = "password"; # Замените на безопасный пароль
          TZ = config.time.timeZone;
        };

        volumes = [
          # Основные тома согласно документации
          "/etc/localtime:/etc/localtime:ro"
          "${cfg.homeDir}:/config"
          "${cfg.storageDir}:/media/frigate"
        ];

        # Устройства для аппаратного ускорения
        devices = lib.flatten [
          # USB Coral
          (lib.optional cfg.enableCoralUsb "/dev/bus/usb:/dev/bus/usb")

          # PCIe Coral
          (lib.optional cfg.enableCoralPcie "/dev/apex_0:/dev/apex_0")

          # Raspberry Pi 4
          (lib.optional cfg.enableRaspberryPi4 "/dev/video11:/dev/video11")

          # Intel Hardware Acceleration
          (lib.optionals cfg.enableIntelHwAccel [
            "/dev/dri/renderD128:/dev/dri/renderD128"
            # Если есть второе устройство Intel GPU
            # "/dev/dri/renderD129:/dev/dri/renderD129"
          ])
        ];

        extraOptions = [
          "--shm-size=${cfg.shmSize}"
          "--stop-timeout=30" # Согласно документации: stop_grace_period
          "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=${cfg.tmpCacheSize}"
        ];
      };

      # Опционально: настройка nginx reverse proxy
      services.nginx.virtualHosts = lib.mkIf (cfgNginx.enable or false) {
        ${cfg.domain} = {
          enableACME = cfgAcme.enable or false;
          forceSSL = cfgAcme.enable or false;
          http2 = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:8971";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              # Для больших файлов (видео)
              client_max_body_size 0;
              proxy_buffering off;
              proxy_request_buffering off;

              # Таймауты для стриминга
              proxy_read_timeout 86400s;
              proxy_send_timeout 86400s;
            '';
          };
        };
      };
    })
  ];
}
