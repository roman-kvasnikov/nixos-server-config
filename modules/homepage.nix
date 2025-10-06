{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # environment.systemVariables = {
  #   HOMEPAGE_ALLOWED_HOSTS = config.server.domain;
  # };

  # https://gethomepage.dev/
  services.homepage-dashboard = {
    enable = true;

    allowedHosts = "${config.server.domain}";

    settings = {
      title = "Kvasnikov's Home Server";

      # background = "${inputs.wallpapers}/landscape_monicore_instagram.jpg";

      background = {
        image = "${inputs.wallpapers}/landscape_monicore_instagram.jpg";
        blur = "sm";
        saturate = "50";
        brightness = "50";
        opacity = "50";
      };

      headerStyle = "boxedWidgets";
    };

    bookmarks = [
      {
        Developer = [
          {
            GitHub = [
              {
                abbr = "GH";
                href = "https://github.com/roman-kvasnikov";
              }
            ];
          }
        ];
      }
      {
        Entertainment = [
          {
            YouTube = [
              {
                abbr = "YT";
                href = "https://youtube.com/";
              }
            ];
          }
        ];
      }
    ];

    # https://gethomepage.dev/latest/configs/services/
    # https://pictogrammers.com/library/mdi/
    services = [
      {
        "Self-hosted services" = [
          {
            "Cockpit" = {
              description = "Cockpit";
              href = "https://cockpit.${config.server.domain}/";
              siteMonitor = "https://cockpit.${config.server.domain}/";
            };
          }
          {
            "Immich" = {
              description = "Immich";
              href = "https://immich.${config.server.domain}/";
              siteMonitor = "https://immich.${config.server.domain}/";
            };
          }
          {
            "Jellyfin" = {
              description = "Jellyfin";
              href = "https://jellyfin.${config.server.domain}/";
              siteMonitor = "https://jellyfin.${config.server.domain}/";
            };
          }
          {
            "Torrent" = {
              description = "Torrent";
              href = "https://torrent.${config.server.domain}/";
              siteMonitor = "https://torrent.${config.server.domain}/";
            };
          }
          {
            "Nextcloud" = {
              description = "Nextcloud";
              href = "https://nextcloud.${config.server.domain}/";
              siteMonitor = "https://nextcloud.${config.server.domain}/";
            };
          }
        ];
      }
      {
        "My Second Group" = [
          {
            "My Second Service" = {
              description = "Homepage is the best";
              href = "https://${config.server.domain}/";
            };
          }
        ];
      }
    ];

    # https://gethomepage.dev/latest/configs/service-widgets/
    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/home";
          memory = true;
          cputemp = true;
          tempmin = 0;
          tempmax = 100;
          uptime = true;
          units = "imperial";
          refresh = 3000;
          diskUnits = "bytes";
          network = true;
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
          };
        };
      }
    ];

    # https://gethomepage.dev/latest/configs/kubernetes/
    # kubernetes = {};

    # https://gethomepage.dev/latest/configs/docker/
    # docker = {};

    # https://gethomepage.dev/latest/configs/custom-css-js/
    # customJS = "";
    # customCSS = "";
  };

  services.nginx = {
    virtualHosts = {
      "${config.server.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    };
  };
}
