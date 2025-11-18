{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.librespeedtl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.librespeedtl = {
    enable = lib.mkEnableOption "Enable LibreSpeed";

    domain = lib.mkOption {
      description = "Domain of the LibreSpeed module";
      type = lib.types.str;
      default = "librespeed.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the LibreSpeed module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the LibreSpeed module";
      type = lib.types.port;
      default = 5444;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to LibreSpeed";
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
        default = "LibreSpeed";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Speed test your internet connection";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "librespeed.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.librespeed = {
        enable = true;

        domain = cfg.domain;

        downloadIPDB = false;

        settings = {
          listen_port = cfg.port;
        };

        useACMEHost = null;
        tlsCertificate = null;
        tlsKey = null;

        frontend = {
          enable = true;
          contactEmail = cfgHomelab.email;
          useNginx = cfgNginx.enable;
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
              allow ${cfgHomelab.wireguardSubnet};
              deny all;
            '';
          };
        };
      };
    })
  ];
}
