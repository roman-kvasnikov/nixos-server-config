# https://gethomepage.dev/
# https://pictogrammers.com/library/mdi/
{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.homepagectl;
in {
  options.homelab.services.homepagectl = {
    enable = lib.mkEnableOption "Enable Homepage";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of the Homepage module";
      default = "${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Homepage module";
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port of the Homepage module";
      default = 8082;
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Homepage";
      default = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.homepage-dashboard = {
        enable = true;

        allowedHosts = "localhost:${toString cfg.port},127.0.0.1:${toString cfg.port},${cfg.domain}";
        listenPort = cfg.port;

        openFirewall = !cfgNginx.enable;

        settings = {
          title = "Kvasnikov's Home Lab";

          layout = [
            {
              Glances = {
                header = false;
                style = "row";
                columns = 6;
              };
            }
            {
              Storages = {
                header = true;
                style = "column";
              };
            }
            {
              Monitoring = {
                header = true;
                style = "column";
              };
            }
            {
              Clouds = {
                header = true;
                style = "column";
              };
            }
            {
              Media = {
                header = true;
                style = "column";
              };
            }
            {
              Services = {
                header = true;
                style = "column";
              };
            }
          ];
          headerStyle = "clean";
          statusStyle = "dot";
          hideVersion = "true";
        };

        # bookmarks = [
        #   {
        #     Developer = [
        #       {
        #         GitHub = [
        #           {
        #             abbr = "GH";
        #             href = "https://github.com/roman-kvasnikov";
        #           }
        #         ];
        #       }
        #     ];
        #   }
        #   {
        #     Entertainment = [
        #       {
        #         YouTube = [
        #           {
        #             abbr = "YT";
        #             href = "https://youtube.com/";
        #           }
        #         ];
        #       }
        #     ];
        #   }
        # ];

        services = let
          homepageCategories = [
            "Monitoring"
            "Clouds"
            "Media"
            "Services"
          ];

          homepageServices = x: (lib.attrsets.filterAttrs (
              _name: value: value ? homepage && value.homepage.enable && value.homepage.category == x
            )
            config.homelab.services);
        in
          lib.lists.forEach homepageCategories (category: {
            "${category}" =
              lib.lists.forEach
              (lib.attrsets.mapAttrsToList (name: _value: name) (homepageServices "${category}"))
              (x: let
                base = {
                  icon = config.homelab.services.${x}.homepage.icon;
                  description = config.homelab.services.${x}.homepage.description;
                  href = "https://${config.homelab.services.${x}.domain}";
                  siteMonitor = "https://${config.homelab.services.${x}.domain}";
                };

                widgetOptions =
                  if lib.hasAttrByPath ["homepage" "widget"] config.homelab.services.${x}
                  then {
                    widget = config.homelab.services.${x}.homepage.widget;
                  }
                  else {};
              in {
                "${config.homelab.services.${x}.homepage.name}" = base // widgetOptions;
              });
          })
          ++ [
            {
              Glances = let
                commonOptions = {
                  type = "glances";
                  url = "http://${cfg.host}:${toString config.services.glances.port}";
                  version = 4;
                };
              in [
                {
                  Info = {
                    widget =
                      commonOptions
                      // {
                        metric = "info";
                      };
                  };
                }
                {
                  Network = {
                    widget =
                      commonOptions
                      // {
                        metric = "network:${cfgHomelab.interface}";
                        chart = true;
                      };
                  };
                }
                {
                  Processes = {
                    widget =
                      commonOptions
                      // {
                        metric = "process";
                        chart = true;
                      };
                  };
                }
                {
                  "Data Storage" = {
                    widget =
                      commonOptions
                      // {
                        metric = "fs:/mnt/data";
                        chart = true;
                      };
                  };
                }
                {
                  "Media Storage" = {
                    widget =
                      commonOptions
                      // {
                        metric = "fs:/mnt/media";
                        chart = true;
                      };
                  };
                }
                {
                  "Frigate Storage" = {
                    widget =
                      commonOptions
                      // {
                        metric = "fs:/var/lib/frigate";
                        chart = true;
                      };
                  };
                }
              ];
            }
          ];

        # https://gethomepage.dev/widgets/
        widgets = [
          {
            resources = {
              label = "Uptime";
              uptime = true;
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
              locale = "ru";
              format = {
                dateStyle = "short";
                timeStyle = "short";
                hourCycle = "h23";
              };
            };
          }
        ];
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.domain}" = {
            default = true;

            enableACME = true;
            forceSSL = true;
            http2 = true;

            extraConfig = ''
              if ($host != "${cfg.domain}") {
                return 404;
              }

              ${
                if cfg.allowExternal
                then ""
                else denyExternal
              }
            '';

            locations."/" = {
              proxyPass = "http://${cfg.host}:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
