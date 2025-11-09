{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.it-tools-ctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.it-tools-ctl = {
    enable = lib.mkEnableOption "Enable IT Tools";

    domain = lib.mkOption {
      description = "Domain of the IT Tools module";
      type = lib.types.str;
      default = "it-tools.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the IT Tools module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the IT Tools module";
      type = lib.types.port;
      default = 5445;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to IT Tools";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "IT Tools";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Useful tools for IT professionals";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "it-tools.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers = {
        it-tools = {
          image = "corentinth/it-tools:latest";
          autoStart = true;
          ports = ["${toString cfg.port}:80"];
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
