{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.filebrowserctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;

  user = "filebrowser";
  group = "filebrowser";
in {
  options.services.filebrowserctl = {
    enable = lib.mkEnableOption {
      description = "Enable Filebrowser";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      filebrowser
    ];

    services.filebrowser = {
      enable = true;

      user = user;
      group = group;

      settings = {};
    };

    users = {
      users.${user} = {
        isSystemUser = true;
        group = group;
      };

      groups.${group} = {};
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "files.${config.server.domain}" = {
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
