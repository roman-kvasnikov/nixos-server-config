{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cockpitctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.cockpitctl = {
    enable = lib.mkEnableOption "Enable Cockpit";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Cockpit module";
      default = "cockpit.${cfgServer.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Cockpit";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Self-hosted system management solution";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "cockpit.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "System";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        cockpit
      ];

      services.cockpit = {
        enable = true;

        allowed-origins = [
          cfg.host
        ];

        settings = {
          WebService = {
            AllowUnencrypted = false;
          };
        };
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
    })
  ];
}
