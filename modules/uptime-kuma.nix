{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.uptime-kumactl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.uptime-kumactl = {
    enable = lib.mkEnableOption "Enable Immich";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Uptime Kuma module";
      default = "uptime.${config.server.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      uptime-kuma
    ];

    services.uptime-kuma = {
      enable = true;
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.host}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3001";
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
