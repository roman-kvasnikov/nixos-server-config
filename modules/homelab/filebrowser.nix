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

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Filebrowser module";
      default = "files.${cfgHomelab.domain}";
    };

    rootDir = lib.mkOption {
      type = lib.types.path;
      description = "The directory where FileBrowser stores files.";
      default = "/data/filebrowser/data";
    };

    databaseFile = lib.mkOption {
      type = lib.types.path;
      description = "The path to FileBrowser's Bolt database.";
      default = "/data/filebrowser/database.db";
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
          address = "127.0.0.1";
          port = 8081;
          root = cfg.rootDir;
          database = cfg.databaseFile;
        };

        extraConfig = ''
          {
            "auth": { "method": "noauth" }
          }
        '';
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.filebrowser.settings.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
