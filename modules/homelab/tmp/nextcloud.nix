{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.nextcloudctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    domain = lib.mkOption {
      description = "Domain of the Nextcloud module";
      type = lib.types.str;
      default = "nextcloud.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Nextcloud module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Nextcloud module";
      type = lib.types.port;
      default = 8090;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Nextcloud";
      type = lib.types.bool;
      default = true;
    };

    adminUser = lib.mkOption {
      description = "Admin user for Nextcloud";
      type = lib.types.str;
      default = cfgHomelab.adminUser;
    };

    adminPasswordFile = lib.mkOption {
      description = "Admin password file for Nextcloud";
      type = lib.types.path;
      default = config.age.secrets.admin-password.path;
    };

    apps = lib.mkOption {
      description = "List of Nextcloud apps to enable";
      type = lib.types.listOf lib.types.str;
      default = ["calendar" "contacts" "notes" "onlyoffice"];
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Nextcloud";
      type = lib.types.bool;
      default = true;
    };

    logFile = lib.mkOption {
      description = "Log file for Nextcloud";
      type = lib.types.path;
      default = "/var/lib/nextcloud/data/nextcloud.log";
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Nextcloud";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Enterprise File Storage and Collaboration";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "nextcloud.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
      # widget = lib.mkOption {
      #   type = lib.types.attrs;
      #   default = {
      #     type = "nextcloud";
      #     url = "https://${cfg.domain}";
      #   };
      # };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [80 443 8443 12345];

      virtualisation.oci-containers.containers = {
        nextcloud-aio-mastercontainer = {
          image = "ghcr.io/nextcloud-releases/all-in-one:latest";
          autoStart = true;
          volumes = [
            "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
          ports = [
            "80:80"
            "12345:443"
            "8443:8443"
          ];
          # environment = {
          #   WATCHTOWER_DOCKER_SOCKET_PATH = "/var/run/docker.sock";
          # };
        };
      };
    })

    # (lib.mkIf (cfg.enable && cfgAcme.enable) {
    #   security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    # })

    # (lib.mkIf (cfg.enable && cfgNginx.enable) {
    #   services.nginx = {
    #     virtualHosts = {
    #       "${cfg.domain}" = {
    #         enableACME = cfgAcme.enable;
    #         forceSSL = cfgAcme.enable;
    #         http2 = true;

    #         extraConfig = lib.mkIf (!cfg.allowExternal) ''
    #           allow ${cfgHomelab.subnet};
    #           allow ${cfgHomelab.vpnSubnet};
    #           deny all;
    #         '';
    #       };
    #     };
    #   };
    # })
  ];
}
