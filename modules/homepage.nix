{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemVariables = {
    HOMEPAGE_ALLOWED_HOSTS = config.server.domain;
  };

  services.homepage-dashboard = {
    enable = true;

    # https://pictogrammers.com/library/mdi/
    services = [
      {
        "Self-hosted services" = [
          {
            "Blog" = {
              description = "Blog";
              href = "http://${config.server.domain}/";
              siteMonitor = "http://blog.${config.server.domain}/";
              icon = "sonarr.png";
            };
            "Immich" = {
              description = "Immich";
              href = "http://immich.${config.server.domain}/";
              siteMonitor = "http://immich.${config.server.domain}/";
            };
          }
        ];
      }
      {
        "My Second Group" = [
          {
            "My Second Service" = {
              description = "Homepage is the best";
              href = "http://${config.server.domain}/";
            };
          }
        ];
      }
    ];

    settings = {
      # startUrl: https://custom.url
      title = "hello world";
    };

    # listenPort=
    # oopenFirewall
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
