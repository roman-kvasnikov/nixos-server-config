{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.filebrowserctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.filebrowserctl = {
    enable = lib.mkEnableOption "Enable Filebrowser";

    domain = lib.mkOption {
      description = "Domain of the Filebrowser module";
      type = lib.types.str;
      default = "files.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Filebrowser module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Filebrowser module";
      type = lib.types.port;
      default = 8081;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Filebrowser";
      type = lib.types.bool;
      default = false;
    };

    rootDir = lib.mkOption {
      description = "The directory where FileBrowser stores files.";
      type = lib.types.path;
      default = "/data/filebrowser";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Filebrowser";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "File browser";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "filebrowser.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.filebrowser = {
        enable = true;

        user = "filebrowser";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        settings = {
          address = cfg.host;
          port = cfg.port;
          root = cfg.rootDir;
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
