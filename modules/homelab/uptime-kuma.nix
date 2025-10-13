{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.uptime-kumactl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.uptime-kumactl = {
    enable = lib.mkEnableOption "Enable Uptime Kuma";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Uptime Kuma module";
      default = "uptime-kuma.${cfgServer.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Uptime Kuma";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Uptime monitoring";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "uptime-kuma.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "System";
      };
      # widget = lib.mkOption {
      #   type = lib.types.attrs;
      #   default = {
      #     type = "uptimekuma";
      #     url = "https://${cfg.host}";
      #     slug = "izolda-rally";
      #   };
      # };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        uptime-kuma
      ];

      services.uptime-kuma = {
        enable = true;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
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
    })
  ];
}
