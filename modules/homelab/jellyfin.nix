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

    initialDirectory = lib.mkOption {
      type = lib.types.path;
      description = "Initial directory for Jellyfin";
      default = "/";
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
        "d ${cfg.initialDirectory}/media 0755 root root - -"
        "d ${cfg.initialDirectory}/media/Movies 0770 ${cfgServer.systemUser} ${cfgServer.systemGroup} - -"
        "d ${cfg.initialDirectory}/media/TV\ Shows 0770 ${cfgServer.systemUser} ${cfgServer.systemGroup} - -"
        "d ${cfg.initialDirectory}/media/Cartoons 0770 ${cfgServer.systemUser} ${cfgServer.systemGroup} - -"
      ];

      users.users.jellyfin = {
        isSystemUser = true;
        group = cfgServer.systemGroup;
        extraGroups = ["video"];
      };

      services.jellyfin = {
        enable = true;

        user = "jellyfin";
        group = cfgServer.systemGroup;

        openFirewall = !cfgNginx.enable;
      };

      systemd.services.jellyfin = {
        serviceConfig = {
          SupplementaryGroups = ["video"]; # доступ к /dev/dri
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
