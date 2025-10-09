# https://gethomepage.dev/
# https://pictogrammers.com/library/mdi/
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.homelab.services.homepagectl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.homepagectl = {
    enable = lib.mkEnableOption "Enable Homepage";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Homepage module";
      default = "${cfgServer.domain}";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.glances.enable = true;

      services.homepage-dashboard = {
        enable = true;

        allowedHosts = "${cfg.host}";

        settings = {
          title = "Kvasnikov's Home Server";

          layout = [
            {
              Glances = {
                header = false;
                style = "row";
                columns = 5;
              };
            }
            {
              Arr = {
                header = true;
                style = "column";
              };
            }
            {
              Downloads = {
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
              System = {
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
            "Arr"
            "Media"
            "Downloads"
            "System"
            "Smart Home"
          ];
          homepageServices = x: (lib.attrsets.filterAttrs (
              _name: value: value ? homepage && value.homepage.category == x
            )
            config.homelab.services);
        in
          lib.lists.forEach homepageCategories (cat: {
            "${cat}" =
              lib.lists.forEach (lib.attrsets.mapAttrsToList (name: _value: name) (homepageServices "${cat}"))
              (x: {
                "${config.homelab.services.${x}.homepage.name}" = {
                  icon = config.homelab.services.${x}.homepage.icon;
                  description = config.homelab.services.${x}.homepage.description;
                  href = "https://${config.homelab.services.${x}.host}";
                  siteMonitor = "https://${config.homelab.services.${x}.host}";
                };
              });
          })
          ++ [
            {
              Glances = let
                port = toString config.services.glances.port;
              in [
                {
                  CPU = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "cpu";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Memory = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "memory";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  "CPU Temp" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "sensor:Core 0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Disk = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "fs:/";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Processes = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "process";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Network = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "network:enp1s0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
              ];
            }
          ];

        # https://gethomepage.dev/latest/configs/service-widgets/
        # widgets = [
        #   {
        #     resources = {
        #       cpu = true;
        #       disk = "/home";
        #       memory = true;
        #       cputemp = true;
        #       tempmin = 0;
        #       tempmax = 100;
        #       uptime = true;
        #       units = "imperial";
        #       refresh = 3000;
        #       diskUnits = "bytes";
        #       network = true;
        #     };
        #   }
        #   {
        #     search = {
        #       provider = "google";
        #       target = "_blank";
        #     };
        #   }
        #   {
        #     datetime = {
        #       text_size = "xl";
        #       format = {
        #         timeStyle = "short";
        #       };
        #     };
        #   }
        # ];

        # https://gethomepage.dev/latest/configs/kubernetes/
        # kubernetes = {};

        # https://gethomepage.dev/latest/configs/docker/
        # docker = {};

        # https://gethomepage.dev/latest/configs/custom-css-js/
        # customJS = "";
        # customCSS = ''
        #   body, html {
        #     font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        #   }
        #   .font-medium {
        #     font-weight: 700 !important;
        #   }
        #   .font-light {
        #     font-weight: 500 !important;
        #   }
        #   .font-thin {
        #     font-weight: 400 !important;
        #   }
        #   #information-widgets {
        #     padding-left: 1.5rem;
        #     padding-right: 1.5rem;
        #   }
        #   div#footer {
        #     display: none;
        #   }
        #   .services-group.basis-full.flex-1.px-1.-my-1 {
        #     padding-bottom: 3rem;
        #   };
        # '';
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
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
    })
  ];
}
