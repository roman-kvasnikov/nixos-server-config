{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.jellyfinctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.jellyfinctl = {
    enable = lib.mkEnableOption "Enable Jellyfin";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Jellyfin module";
      default = "jellyfin.${cfgServer.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Jellyfin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Media server";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Media";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "jellyfin";
          url = "https://${cfg.host}";
          key = "f4342ca21fec4d50a9a29e106b8a11fc";
          enableBlocks = true;
          enableNowPlaying = true;
          enableUser = true;
          enableMediaControl = false;
          showEpisodeNumber = true;
          expandOneStreamToTwoRows = false;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # nixpkgs.overlays = [
      #   (_final: prev: {
      #     jellyfin-web = prev.jellyfin-web.overrideAttrs (
      #       _finalAttrs: _previousAttrs: {
      #         installPhase = ''
      #           runHook preInstall

      #           # this is the important line
      #           sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

      #           mkdir -p $out/share
      #           cp -a dist $out/share/jellyfin-web

      #           runHook postInstall
      #         '';
      #       }
      #     );
      #   })
      # ];

      environment.systemPackages = with pkgs; [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
      ];

      users.users.jellyfin = {
        isSystemUser = true;
        group = cfgServer.systemGroup;
      };

      services.jellyfin = {
        enable = true;

        user = "jellyfin";
        group = cfgServer.systemGroup;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      networking.firewall.allowedTCPPorts = [8096]; # Для доступа из внешней сети

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
