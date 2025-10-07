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
    enable = lib.mkEnableOption "Enable Cockpit";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Cockpit module";
      default = "cockpit.${config.server.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cockpit
    ];

    services.cockpit = {
      enable = true;

      allowed-origins = [
        cfg.host
      ];

      settings = {};
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.host}" = {
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
