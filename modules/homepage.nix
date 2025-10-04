{
  config,
  lib,
  pkgs,
  ...
}: {
  # environment.systemVariables = {
  #   HOMEPAGE_ALLOWED_HOSTS = config.server.domain;
  # };

  services.homepage-dashboard = {
    enable = true;

    allowedHosts = "cockpit.${config.server.domain}";

    # https://gethomepage.dev/latest/configs/settings/
    settings = {
      title = "Kvasnikov's Home Server";
      description = "My NixOS Home Server Configuration";
      startUrl = "https://cockpit.${config.server.domain}/";
      # theme = "dark";
      # color = "slate";
    };

    # https://gethomepage.dev/latest/configs/bookmarks/
    bookmarks = [
      {
        Developer = [
          {
            Github = [
              {
                abbr = "GH";
                href = "https://github.com/";
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
          disk = "/";
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
      "cockpit.${config.server.domain}" = {
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
