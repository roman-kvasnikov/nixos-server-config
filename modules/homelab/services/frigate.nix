{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.frigatectl;
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
      default = 8971;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Frigate data and recordings";
      default = "/var/lib/frigate";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Frigate";
      type = lib.types.bool;
      default = false;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
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
          url = "http://${cfg.host}:5000/";
          enableRecentEvents = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        frigate = {
          image = "ghcr.io/blakeblackshear/frigate:stable";
          autoStart = true;
          privileged = true;
          devices = [
            "/dev/dri/renderD128:/dev/dri/renderD128"
            # "/dev/dri/renderD129:/dev/dri/renderD129"
          ];
          ports = [
            "${toString cfg.port}:8971/tcp" # For the Web GUI
            "5000:5000/tcp" # For the Homepage widget
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${cfg.dataDir}:/config"
            "${cfg.dataDir}/storage:/media/frigate"
          ];
          extraOptions = [
            # "--restart=unless-stopped"
            # "--device=nvidia.com/gpu=all"
            "--stop-timeout=30"
            "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
            "--shm-size=512mb"
          ];
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

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
