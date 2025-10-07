{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jellyfinctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.jellyfinctl = {
    enable = lib.mkEnableOption "Enable Jellyfin";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Jellyfin module";
      default = "jellyfin.${cfgServer.domain}";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [
        (_final: prev: {
          jellyfin-web = prev.jellyfin-web.overrideAttrs (
            _finalAttrs: _previousAttrs: {
              installPhase = ''
                runHook preInstall

                # this is the important line
                sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

                mkdir -p $out/share
                cp -a dist $out/share/jellyfin-web

                runHook postInstall
              '';
            }
          );
        })
      ];

      environment.systemPackages = with pkgs; [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
      ];

      services.jellyfin = {
        enable = true;

        user = cfgServer.systemUser;
        group = cfgServer.systemGroup;
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
              proxyPass = "http://127.0.0.1:8096";
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
