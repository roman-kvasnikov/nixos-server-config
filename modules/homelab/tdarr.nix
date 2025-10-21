{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.tdarrctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.tdarrctl = {
    enable = lib.mkEnableOption "Enable Tdarr";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Tdarr module";
      default = "tdarr.${cfgServer.domain}";
    };

    # User configuration
    uid = lib.mkOption {
      type = lib.types.int;
      description = "User ID for tdarr service";
      default = 1000;
    };

    # Tdarr-specific configuration
    serverPort = lib.mkOption {
      type = lib.types.int;
      description = "Server port for Tdarr";
      default = 8266;
    };

    webUIPort = lib.mkOption {
      type = lib.types.int;
      description = "Web UI port for Tdarr";
      default = 8265;
    };

    internalNode = lib.mkOption {
      type = lib.types.bool;
      description = "Enable internal node in the server container";
      default = true;
    };

    enableNode = lib.mkOption {
      type = lib.types.bool;
      description = "Enable separate Tdarr node container";
      default = false;
    };

    ffmpegVersion = lib.mkOption {
      type = lib.types.int;
      description = "FFmpeg version to use";
      default = 7;
    };

    nodeName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the internal node";
      default = "InternalNode";
    };

    auth = lib.mkOption {
      type = lib.types.bool;
      description = "Enable authentication";
      default = false;
    };

    mediaPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of media paths to mount";
      default = ["/media"];
    };

    transcodeCachePath = lib.mkOption {
      type = lib.types.str;
      description = "Path for transcode cache";
      default = "/var/lib/tdarr/transcode_cache";
    };

    serverDataPath = lib.mkOption {
      type = lib.types.str;
      description = "Path for server data";
      default = "/var/lib/tdarr/server";
    };

    configsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path for configs";
      default = "/var/lib/tdarr/configs";
    };

    logsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path for logs";
      default = "/var/lib/tdarr/logs";
    };

    enableGPU = lib.mkOption {
      type = lib.types.bool;
      description = "Enable GPU support for transcoding";
      default = false;
    };

    enableIntelGPU = lib.mkOption {
      type = lib.types.bool;
      description = "Enable Intel GPU support (QuickSync)";
      default = false;
    };

    enableNvidiaGPU = lib.mkOption {
      type = lib.types.bool;
      description = "Enable NVIDIA GPU support";
      default = false;
    };

    transcodecpuWorkers = lib.mkOption {
      type = lib.types.int;
      description = "Number of CPU transcode workers";
      default = 2;
    };

    transcodegpuWorkers = lib.mkOption {
      type = lib.types.int;
      description = "Number of GPU transcode workers";
      default = 1;
    };

    healthcheckcpuWorkers = lib.mkOption {
      type = lib.types.int;
      description = "Number of CPU healthcheck workers";
      default = 1;
    };

    healthcheckgpuWorkers = lib.mkOption {
      type = lib.types.int;
      description = "Number of GPU healthcheck workers";
      default = 1;
    };

    maxLogSizeMB = lib.mkOption {
      type = lib.types.int;
      description = "Maximum log size in MB";
      default = 10;
    };

    # Resource limits
    cpuLimit = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "CPU limit for container";
      default = null;
      example = "2.0";
    };

    memoryLimit = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Memory limit for container";
      default = null;
      example = "4G";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Tdarr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Distributed transcoding system";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "tdarr.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "tdarr";
          url = "https://${cfg.host}";
          enableQueue = true;
          enableWorkers = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.enableIntelGPU && cfg.enableNvidiaGPU);
          message = "Cannot enable both Intel and NVIDIA GPU simultaneously";
        }
        {
          assertion = cfg.enableGPU -> (cfg.enableIntelGPU || cfg.enableNvidiaGPU);
          message = "When GPU is enabled, either Intel or NVIDIA GPU must be selected";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      # Set OCI containers backend
      virtualisation.oci-containers.backend = lib.mkDefault "podman";

      # Create necessary directories with proper permissions
      systemd.tmpfiles.rules =
        [
          "d '${cfg.serverDataPath}' 0775 tdarr ${cfgServer.systemGroup} -"
          "d '${cfg.configsPath}' 0775 tdarr ${cfgServer.systemGroup} -"
          "d '${cfg.logsPath}' 0775 tdarr ${cfgServer.systemGroup} -"
          "d '${cfg.transcodeCachePath}' 0775 tdarr ${cfgServer.systemGroup} -"
        ]
        ++ (map (path: "d '${path}' 0775 tdarr ${cfgServer.systemGroup} -") cfg.mediaPaths);

      # Create tdarr user
      users.users.tdarr = {
        isSystemUser = true;
        group = cfgServer.systemGroup;
        home = cfg.serverDataPath;
        createHome = false;
        description = "Tdarr service user";
        uid = cfg.uid;
        extraGroups =
          lib.optional cfg.enableIntelGPU "video"
          ++ lib.optional cfg.enableIntelGPU "render";
      };

      # Docker container for Tdarr
      virtualisation.oci-containers.containers.tdarr = {
        image = "ghcr.io/haveagitgat/tdarr:latest";
        autoStart = true;

        ports = [
          "${toString cfg.webUIPort}:8265"
          "${toString cfg.serverPort}:8266"
        ];

        environment =
          {
            TZ = config.time.timeZone or "UTC";
            PUID = toString cfg.uid;
            PGID = toString config.users.groups.${cfgServer.systemGroup}.gid;
            UMASK_SET = "002";

            serverIP = "0.0.0.0";
            serverPort = toString cfg.serverPort;
            webUIPort = toString cfg.webUIPort;
            internalNode = toString cfg.internalNode;
            inContainer = "true";
            ffmpegVersion = toString cfg.ffmpegVersion;
            nodeName = cfg.nodeName;
            auth = toString cfg.auth;
            openBrowser = "false";
            maxLogSizeMB = toString cfg.maxLogSizeMB;
            cronPluginUpdate = "";

            # Workers configuration
            transcodecpuWorkers = toString cfg.transcodecpuWorkers;
            transcodegpuWorkers = toString cfg.transcodegpuWorkers;
            healthcheckcpuWorkers = toString cfg.healthcheckcpuWorkers;
            healthcheckgpuWorkers = toString cfg.healthcheckgpuWorkers;
          }
          // lib.optionalAttrs cfg.enableNvidiaGPU {
            NVIDIA_DRIVER_CAPABILITIES = "all";
            NVIDIA_VISIBLE_DEVICES = "all";
          };

        volumes =
          [
            "${cfg.serverDataPath}:/app/server:rw"
            "${cfg.configsPath}:/app/configs:rw"
            "${cfg.logsPath}:/app/logs:rw"
            "${cfg.transcodeCachePath}:/temp:rw"
          ]
          ++ (map (path: "${path}:${path}:rw") cfg.mediaPaths);

        extraOptions =
          [
            "--init"
            "--security-opt=no-new-privileges"
            "--cap-drop=ALL"
            "--cap-add=CHOWN"
            "--cap-add=SETUID"
            "--cap-add=SETGID"
            "--cap-add=DAC_OVERRIDE"
            "--health-cmd=curl -f http://localhost:${toString cfg.webUIPort}/api/v2/status || exit 1"
            "--health-interval=30s"
            "--health-timeout=10s"
            "--health-retries=3"
            "--log-driver=journald"
            "--log-opt=tag=tdarr"
          ]
          ++ lib.optionals cfg.enableIntelGPU [
            "--device=/dev/dri:/dev/dri"
          ]
          ++ lib.optionals cfg.enableNvidiaGPU [
            "--gpus=all"
          ]
          ++ lib.optionals (cfg.cpuLimit != null) [
            "--cpus=${cfg.cpuLimit}"
          ]
          ++ lib.optionals (cfg.memoryLimit != null) [
            "--memory=${cfg.memoryLimit}"
          ];
      };

      # Ensure directories are created before container starts
      systemd.services."podman-tdarr" = {
        preStart = ''
          # Ensure directories exist and have correct permissions
          mkdir -p ${cfg.serverDataPath} ${cfg.configsPath} ${cfg.logsPath} ${cfg.transcodeCachePath}
          ${lib.concatMapStrings (path: "mkdir -p ${path}\n") cfg.mediaPaths}

          chown -R ${toString cfg.uid}:${toString config.users.groups.${cfgServer.systemGroup}.gid} \
            ${cfg.serverDataPath} \
            ${cfg.configsPath} \
            ${cfg.logsPath} \
            ${cfg.transcodeCachePath}

          chmod -R 775 ${cfg.serverDataPath} ${cfg.configsPath} ${cfg.logsPath} ${cfg.transcodeCachePath}
        '';
      };

      # Open firewall ports if nginx is not used
      networking.firewall.allowedTCPPorts = lib.mkIf (!cfgNginx.enable) [
        cfg.webUIPort
        cfg.serverPort
      ];
    })

    # Optional: Tdarr Node container (separate from server)
    (lib.mkIf (cfg.enable && cfg.enableNode) {
      virtualisation.oci-containers.containers.tdarr-node = {
        image = "ghcr.io/haveagitgat/tdarr_node:latest";
        autoStart = true;

        ports = [
          "8268:8268"
        ];

        environment =
          {
            TZ = config.time.timeZone or "UTC";
            PUID = toString cfg.uid;
            PGID = toString config.users.groups.${cfgServer.systemGroup}.gid;
            UMASK_SET = "002";

            nodeName = "ExternalNode";
            serverIP = "127.0.0.1"; # Assuming node runs on same host
            serverPort = toString cfg.serverPort;
            inContainer = "true";
            ffmpegVersion = toString cfg.ffmpegVersion;
            nodeType = "mapped";
            priority = "-1";
            cronPluginUpdate = "";
            apiKey = "";
            maxLogSizeMB = toString cfg.maxLogSizeMB;
            pollInterval = "2000";
            startPaused = "false";

            # Workers configuration for node
            transcodecpuWorkers = toString cfg.transcodecpuWorkers;
            transcodegpuWorkers = toString cfg.transcodegpuWorkers;
            healthcheckcpuWorkers = toString cfg.healthcheckcpuWorkers;
            healthcheckgpuWorkers = toString cfg.healthcheckgpuWorkers;
          }
          // lib.optionalAttrs cfg.enableNvidiaGPU {
            NVIDIA_DRIVER_CAPABILITIES = "all";
            NVIDIA_VISIBLE_DEVICES = "all";
          };

        volumes =
          [
            "${cfg.configsPath}:/app/configs:rw"
            "${cfg.logsPath}:/app/logs:rw"
            "${cfg.transcodeCachePath}:/temp:rw"
          ]
          ++ (map (path: "${path}:${path}:rw") cfg.mediaPaths);

        extraOptions =
          [
            "--init"
            "--network=host"
            "--security-opt=no-new-privileges"
            "--cap-drop=ALL"
            "--cap-add=CHOWN"
            "--cap-add=SETUID"
            "--cap-add=SETGID"
            "--cap-add=DAC_OVERRIDE"
            "--log-driver=journald"
            "--log-opt=tag=tdarr-node"
          ]
          ++ lib.optionals cfg.enableIntelGPU [
            "--device=/dev/dri:/dev/dri"
          ]
          ++ lib.optionals cfg.enableNvidiaGPU [
            "--gpus=all"
          ]
          ++ lib.optionals (cfg.cpuLimit != null) [
            "--cpus=${cfg.cpuLimit}"
          ]
          ++ lib.optionals (cfg.memoryLimit != null) [
            "--memory=${cfg.memoryLimit}"
          ];
      };

      # Open firewall port for node
      networking.firewall.allowedTCPPorts = lib.mkIf (!cfgNginx.enable) [
        8268
      ];
    })

    # ACME certificate configuration
    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    # Nginx reverse proxy configuration
    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.webUIPort}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 0;
                proxy_buffering off;
                proxy_request_buffering off;
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
                send_timeout 600s;

                # Additional headers for Tdarr
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $host;
                proxy_set_header X-Forwarded-Server $host;
              '';
            };

            # Server API endpoint
            locations."/api" = {
              proxyPass = "http://127.0.0.1:${toString cfg.serverPort}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 0;
                proxy_buffering off;
                proxy_request_buffering off;
              '';
            };

            # Socket.io endpoint for real-time updates
            locations."/socket.io" = {
              proxyPass = "http://127.0.0.1:${toString cfg.webUIPort}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              # extraConfig = ''
              #   proxy_http_version 1.1;
              #   proxy_set_header Upgrade $http_upgrade;
              #   proxy_set_header Connection "upgrade";
              # '';
            };
          };
        };
      };
    })

    # Enable NVIDIA Docker support if GPU is enabled
    (lib.mkIf (cfg.enable && cfg.enableNvidiaGPU) {
      hardware.nvidia-container-toolkit.enable = true;

      hardware.graphics = {
        enable = true;
        # driSupport = true;
        # driSupport32Bit = true;
      };
    })

    # Enable Intel GPU support
    (lib.mkIf (cfg.enable && cfg.enableIntelGPU) {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-compute-runtime
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    })
  ];
}
