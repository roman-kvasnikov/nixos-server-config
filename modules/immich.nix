{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.immichctl;
  cfgAcme = config.services.acmectl;
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

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "immich.${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:2283";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
          };
        };
      };
    };
  };
}
