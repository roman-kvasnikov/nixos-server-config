{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.linkwardenctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.linkwardenctl = {
    enable = lib.mkEnableOption "Enable Linkwarden";

    domain = lib.mkOption {
      description = "Domain of the Linkwarden module";
      type = lib.types.str;
      default = "linkwarden.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Linkwarden module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Linkwarden module";
      type = lib.types.port;
      default = 3000;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Linkwarden";
      type = lib.types.bool;
      default = true;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Linkwarden";
      type = lib.types.bool;
      default = true;
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Linkwarden";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Bookmarks manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "linkwarden.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.linkwarden = {
        enable = true;

        host = cfg.host;
        port = cfg.port;

        openFirewall = !cfgNginx.enable;

        enableRegistration = true;

        environmentFile = config.age.secrets.linkwarden-env.path;
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.linkwarden = {
          database = "linkwarden";
          paths = ["/var/lib/linkwarden"];
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
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
