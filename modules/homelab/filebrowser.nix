{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.filebrowserctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.filebrowserctl = {
    enable = lib.mkEnableOption "Enable Filebrowser";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Filebrowser module";
      default = "files.${cfgServer.domain}";
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
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "filebrowser";
          url = "https://${cfg.host}";
          username = "admin";
          password = "generator163";
        };
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
        group = cfgServer.systemGroup;

        openFirewall = !cfgNginx.enable;

        settings = {
          port = 8081;
          root = "/";
        };
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
              proxyPass = "http://127.0.0.1:8081";
            };
          };
        };
      };
    })
  ];
}
