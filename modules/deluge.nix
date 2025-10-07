{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.delugectl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.delugectl = {
    enable = lib.mkEnableOption "Enable Deluge";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Deluge module";
      default = "torrent.${config.server.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      deluge
    ];

    services.deluge = {
      enable = true;

      user = config.server.systemUser;
      group = config.server.systemGroup;
      web = {
        enable = true;
      };
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.host}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8112";
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
