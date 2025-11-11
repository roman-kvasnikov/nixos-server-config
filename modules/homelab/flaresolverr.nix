{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.flaresolverrctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.flaresolverrctl = {
    enable = lib.mkEnableOption "Enable Flaresolverr";

    domain = lib.mkOption {
      description = "Domain of the Flaresolverr module";
      type = lib.types.str;
      default = "flaresolverr.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Flaresolverr module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Flaresolverr module";
      type = lib.types.port;
      default = 8191;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Flaresolverr";
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
        default = "Flaresolverr";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Proxy for resolving media URLs";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "flaresolverr.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.flaresolverr = {
        enable = true;

        port = cfg.port;

        openFirewall = !cfgNginx.enable;
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
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
