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
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
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
                  url = "http://localhost:${toString config.services.glances.port}";
                  version = 4;
                };
              in [
                {
                  CPU = {
                    widget =
                      commonOptions
                      // {
                        metric = "cpu";
                        chart = true;
                      };
                  };
                }
                {
                  "CPU Temp" = {
                    widget =
                      commonOptions
                      // {
                        metric = "sensor:Core 0";
                        chart = true;
                      };
                  };
                }
                # {
                #   "GPU" = {
                #     widget =
                #       commonOptions
                #       // {
                #         metric = "sensors";
                #         chart = true;
                #       };
                #   };
                # }
                {
                  Memory = {
                    widget =
                      commonOptions
                      // {
                        metric = "memory";
                        chart = true;
                      };
                  };
                }
                {
                  Disk = {
                    widget =
                      commonOptions
                      // {
                        metric = "fs:/";
                        chart = true;
                      };
                  };
                }
                {
                  "Network Usage" = {
                    widget =
                      commonOptions
                      // {
                        metric = "network:enp0s20f0u9";
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
              ];
            }
          ];

        # https://gethomepage.dev/widgets/
        widgets = [
          {
            resources = {
              label = "CPU";
              cpu = true;
              cputemp = true;
              tempmin = 0;
              tempmax = 100;
              units = "metric";
            };
          }
          {
            resources = {
              label = "RAM";
              memory = true;
            };
          }
          {
            resources = {
              label = "Storage";
              expanded = true;
              diskUnits = "bytes";
              disk = [
                "/"
                "/var/lib/frigate"
              ];
            };
          }
          {
            resources = {
              label = "Network";
              network = true;
            };
          }
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
                else ''
                  allow ${cfgHomelab.subnet};
                  allow ${cfgHomelab.vpnSubnet};
                  deny all;
                ''
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
