{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.immichctl;
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

    services.nginx.virtualHosts = lib.mkIf cfgNginx.enable {
      "immich.${config.server.domain}" = {
        proxyPass = "http://127.0.0.1:2283";
      };
    };
  };
}
