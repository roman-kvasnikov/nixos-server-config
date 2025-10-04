{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cockpitctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.cockpitctl = {
    enable = lib.mkEnableOption {
      description = "Enable Cockpit";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cockpit
    ];

    services.cockpit = {
      enable = true;

      settings = {
        WebService = {
          AllowUnencrypted = false;
        };
      };
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9090";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 500M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;

              # Cockpit обычно использует заголовки WebSocket, но
              # proxyWebsockets = true уже это покрывает.
            '';
          };
        };
      };
    };
  };
}
