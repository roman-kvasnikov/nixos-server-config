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
      type = lib.types.str;
      description = "Domain of the Filebrowser module";
      default = "files.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Filebrowser module";
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port of the Filebrowser module";
      default = 8081;
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Filebrowser";
      default = false;
    };

    rootDir = lib.mkOption {
      type = lib.types.path;
      description = "The directory where FileBrowser stores files.";
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
      environment.systemPackages = with pkgs; [
        filebrowser
      ];

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
            enableACME = true;
            forceSSL = true;
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
