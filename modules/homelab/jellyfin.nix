{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.jellyfinctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.jellyfinctl = {
    enable = lib.mkEnableOption "Enable Jellyfin";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Jellyfin module";
      default = "jellyfin.${cfgHomelab.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Home directory for Jellyfin";
      default = "/data/jellyfin";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      description = "Config directory for Jellyfin";
      default = "/data/jellyfin/config";
    };

    logDir = lib.mkOption {
      type = lib.types.path;
      description = "Log directory for Jellyfin";
      default = "/data/jellyfin/log";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      description = "Media directory for Jellyfin";
      default = "/data/media";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Jellyfin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Free Software Media System";
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
          key = "3a417e965c3b4b19a273b469269ff7dd";
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

      systemd.tmpfiles.rules = [
        "d ${cfg.mediaDir} 0755 root root - -"
        "d ${cfg.mediaDir}/Movies 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.mediaDir}/TV\ Shows 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
        "d ${cfg.mediaDir}/Cartoons 0770 ${cfgHomelab.systemUser} ${cfgHomelab.systemGroup} - -"
      ];

      users.users.jellyfin = {
        extraGroups = ["video" "render"];
      };

      services.jellyfin = {
        enable = true;

        user = "jellyfin";
        group = cfgHomelab.systemGroup;

        openFirewall = !cfgNginx.enable;

        dataDir = cfg.dataDir;
        configDir = cfg.configDir;
        logDir = cfg.logDir;
      };

      systemd.services.jellyfin = {
        serviceConfig = {
          SupplementaryGroups = ["video" "render"]; # доступ к /dev/dri
        };
      };

      hardware = {
        graphics = {
          enable = true;

          extraPackages = with pkgs; [
            intel-media-driver # для Intel (новые GPU)
            vaapiIntel # для старых Intel
            vaapiVdpau
            libvdpau-va-gl
          ];
        };

        nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          modesetting.enable = true;
          nvidiaPersistenced = true;
          open = false; # ❌ Оставляем проприетарные (закрытые) драйверы для GTX 10XX и выше
        };
      };

      services.xserver.videoDrivers = ["nvidia"];
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
            http2 = true;

            # Безопасность
            extraConfig = ''
              # Максимальный размер тела запроса (например, для постеров и т.п.)
              client_max_body_size 20M;

              # Безопасность / XSS защита
              add_header X-Content-Type-Options "nosniff";

              # Permissions Policy — может вызвать проблемы у старых клиентов, но безопаснее
              add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;

              # Content Security Policy (CSP)
              add_header Content-Security-Policy "default-src https: data: blob:; img-src 'self' https://*; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";
            '';

            # Основной Jellyfin-прокси
            locations."/" = {
              proxyPass = "http://127.0.0.1:8096";
              proxyWebsockets = true;
              recommendedProxySettings = true;

              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host     $http_host;

                proxy_buffering off;
              '';
            };

            # WebSocket-соединения (альтернативный location /socket)
            locations."/socket" = {
              proxyPass = "http://127.0.0.1:8096";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
                proxy_set_header X-Forwarded-Host     $http_host;

                proxy_buffering off;
              '';
            };
          };

          # HTTP → HTTPS редирект
          "redirect-${cfg.host}" = {
            serverName = "${cfg.host}";
            listen = [
              {
                addr = "0.0.0.0";
                port = 80;
              }
              {
                addr = "[::]";
                port = 80;
              }
            ];
            extraConfig = ''
              return 301 https://$host$request_uri;
            '';
          };
        };
      };
    })
  ];
}
