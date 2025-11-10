{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.portainerctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.portainerctl = {
    enable = lib.mkEnableOption "Enable Portainer";

    domain = lib.mkOption {
      description = "Domain of the Portainer module";
      type = lib.types.str;
      default = "portainer.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Portainer module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Portainer module";
      type = lib.types.port;
      default = 9443;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Portainer";
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
        default = "Portainer";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Container management platform";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "portainer.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "portainer";
          url = "https://${cfg.domain}";
          env = 3;
          key = "ptr_30UTOzVYQsIxTTUMBwC3xiElX62hM2cKZRsNO86tEsE";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        portainer = {
          image = "portainer/portainer-ce:latest";
          autoStart = true;
          ports = [
            "${toString cfg.port}:9000"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/var/lib/portainer:/data"
          ];
          environment = {
            TZ = config.time.timeZone;
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

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              deny all;
            '';

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
