{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.piholectl;
in {
  options.homelab.services.piholectl = {
    enable = lib.mkEnableOption "Enable Pi-hole";

    domain = lib.mkOption {
      description = "Domain of the Pi-hole module";
      type = lib.types.str;
      default = "pi-hole.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Pi-hole module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Pi-hole module";
      type = lib.types.port;
      default = 8020;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory for Pi-hole configurations";
      default = "/mnt/data/AppData/Pi-hole";
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Pi-hole";
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
        default = "Pi-hole";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "DNS server and ad blocker";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "pi-hole.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "pihole";
          url = "http://0.0.0.0:${toString cfg.port}/";
          version = 6;
          key = "correct horse battery staple";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        pihole = {
          image = "pihole/pihole:latest";
          autoStart = true;
          ports = [
            "53:53/tcp"
            "53:53/udp"
            "${toString cfg.port}:80/tcp"
          ];
          volumes = [
            "${cfg.dataDir}:/etc/pihole"
          ];
          environment = {
            TZ = config.time.timeZone;
            FTLCONF_webserver_api_password = "correct horse battery staple";
            FTLCONF_dns_listeningMode = "ALL";
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
