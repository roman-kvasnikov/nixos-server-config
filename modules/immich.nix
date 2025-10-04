{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.immichctl;
  cfgServer = config.server;
  cfgNginx = config.services.nginxctl;
in {
  options.services.immichctl = {
    enable = lib.mkEnableOption {
      description = "Enable Immich";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      immich
    ];

    services.immich = {
      enable = true;

      host = "0.0.0.0";
      port = 2283;

      openFirewall = true;
    };

    config = lib.mkIf cfgNginx.enable {
      services.nginx.virtualHosts = {
        "immich.${cfgServer.domain}" = {
          proxyPass = "http://127.0.0.1:2283";
        };
      };
    };
  };
}
