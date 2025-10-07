{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.filebrowserctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.filebrowserctl = {
    enable = lib.mkEnableOption "Enable Filebrowser";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Filebrowser module";
      default = "files.${config.server.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      filebrowser
    ];

    services.filebrowser = {
      enable = true;

      user = config.server.systemUser;
      group = config.server.systemGroup;

      settings = {};
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.host}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080"; # порт Filebrowser по умолчанию
          };
        };
      };
    };
  };
}
