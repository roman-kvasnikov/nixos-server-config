{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.filebrowserctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.filebrowserctl = {
    enable = lib.mkEnableOption "Enable Filebrowser";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Filebrowser module";
      default = "files.${cfgServer.domain}";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        filebrowser
      ];

      services.filebrowser = {
        enable = true;

        user = cfgServer.systemUser;
        group = cfgServer.systemGroup;

        settings = {};
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
              proxyPass = "http://127.0.0.1:8080";
            };
          };
        };
      };
    })
  ];
}
