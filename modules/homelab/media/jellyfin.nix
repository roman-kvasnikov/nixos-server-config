{
  config,
  lib,
  pkgs,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.jellyfinctl;
in {
  options.homelab.services.jellyfinctl = {
    enable = lib.mkEnableOption "Enable Jellyfin";

    domain = lib.mkOption {
      description = "Domain of the Jellyfin module";
      type = lib.types.str;
      default = "jellyfin.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Jellyfin module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Jellyfin module";
      type = lib.types.port;
      default = 8096;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Jellyfin";
      type = lib.types.bool;
      default = false;
    };

    backupEnabled = lib.mkOption {
      description = "Enable backup for Jellyfin";
      type = lib.types.bool;
      default = true;
    };

    mediaDir = lib.mkOption {
      description = "Media directory for Jellyfin";
      type = lib.types.path;
      default = "/mnt/media/Media";
    };

    mediaFolders = lib.mkOption {
      description = "Media folders for Jellyfin";
      type = lib.types.listOf lib.types.str;
      default = ["Cartoons" "Movies" "Shows"];
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Jellyfin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Free software Media System";
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
          url = "https://${cfg.domain}";
          key = "b1056c4f71ab472899d94f82be26b49a";
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

      systemd.tmpfiles.rules =
        ["d ${cfg.mediaDir} 2775 jellyfin media - -"]
        ++ (lib.map (folder: "d ${cfg.mediaDir}/${folder} 2775 jellyfin media - -") cfg.mediaFolders);

      services.jellyfin = {
        enable = true;

        openFirewall = !cfgNginx.enable;
      };

      users.users.jellyfin = {
        extraGroups = ["video" "render" "media"];
      };

      systemd.services.jellyfin = {
        serviceConfig = {
          SupplementaryGroups = ["video" "render"];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.backupEnabled) {
      services.backupctl = {
        jobs.jellyfin = {
          paths = [config.services.jellyfin.dataDir];
        };
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.domain}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            http2 = true;

            # Безопасность
            extraConfig = ''
              ${
                if cfg.allowExternal
                then ""
                else denyExternal
              }

              client_max_body_size 20M;

              # Security / XSS Mitigation Headers
              add_header X-Content-Type-Options "nosniff";

              # Permissions policy. May cause issues with some clients
              add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;

              # Content Security Policy
              # See: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
              # Enforces https content and restricts JS/CSS to origin
              # External Javascript (such as cast_sender.js for Chromecast) must be whitelisted.
              add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";
            '';

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              recommendedProxySettings = true;

              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host     $http_host;

                proxy_buffering off;
              '';
            };

            locations."/socket" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host     $http_host;
              '';
            };
          };
        };
      };
    })
  ];
}
