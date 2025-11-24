{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.jitsi-meet-ctl;
in {
  options.homelab.services.jitsi-meet-ctl = {
    enable = lib.mkEnableOption "Enable Jitsi Meet";

    domain = lib.mkOption {
      description = "Domain of the Jitsi Meet module";
      type = lib.types.str;
      default = "jitsi-meet.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Jitsi Meet module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Jitsi Meet module";
      type = lib.types.port;
      default = 3002;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Jitsi Meet";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Jitsi Meet";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Video conferencing for your home";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "jitsi-meet.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.jitsi-meet = {
        enable = true;

        hostName = cfg.domain;

        nginx.enable = true;

        excalidraw.port = cfg.port;
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
          };
        };
      };
    })
  ];
}
