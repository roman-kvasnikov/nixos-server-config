{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.unifictl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.unifictl = {
    enable = lib.mkEnableOption {
      description = "Enable UniFi";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unifi
    ];

    services.unifi = {
      enable = true;
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "unifi.${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "https://127.0.0.1:8443";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 100M;

              # UniFi uses WebSockets and long polling, so timeouts should be high
              proxy_connect_timeout   300;
              proxy_send_timeout      300;
              proxy_read_timeout      300;
              send_timeout            300;

              # Ignore SSL cert from UniFi backend (self-signed)
              proxy_ssl_verify off;
              proxy_ssl_session_reuse off;
            '';
          };
        };
      };
    };
  };
}
