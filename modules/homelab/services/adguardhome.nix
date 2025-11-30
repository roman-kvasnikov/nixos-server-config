{
  config,
  lib,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.adguardhomectl;
in {
  options.homelab.services.adguardhomectl = {
    enable = lib.mkEnableOption "Enable AdGuard Home";

    domain = lib.mkOption {
      description = "Domain of the AdGuard Home module";
      type = lib.types.str;
      default = "adguardhome.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the AdGuard Home module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the AdGuard Home module";
      type = lib.types.port;
      default = 3007;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to AdGuard Home";
      type = lib.types.bool;
      default = false;
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "AdGuard Home";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "DNS server and ad blocker with parental control";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "adguard-home.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "adguard";
          url = "http://${cfg.host}:${toString cfg.port}/";
          username = "admin";
          password = "admin";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.adguardhome = {
        enable = true;

        host = cfg.host;
        port = cfg.port;

        openFirewall = !cfgNginx.enable;

        mutableSettings = true;

        settings = {
          dns = {
            upstream_dns = [
              "8.8.8.8"
              "1.1.1.1"
            ];
          };

          filters =
            map (url: {
              enabled = true;
              url = url;
            }) [
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
            ];
        };
      };

      networking.firewall.allowedTCPPorts = [53];
      networking.firewall.allowedUDPPorts = [53];
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

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;

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
