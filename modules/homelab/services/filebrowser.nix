{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.filebrowserctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.filebrowserctl = {
    enable = lib.mkEnableOption "Enable Filebrowser";

    domain = lib.mkOption {
      description = "Domain of the Filebrowser module";
      type = lib.types.str;
      default = "files.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Filebrowser module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Filebrowser module";
      type = lib.types.port;
      default = 8081;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Filebrowser";
      type = lib.types.bool;
      default = false;
    };

    rootDir = lib.mkOption {
      description = "The directory where FileBrowser stores files.";
      type = lib.types.path;
      default = "/mnt/data/AppData/Filebrowser";
    };

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Filebrowser";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "File browser";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "filebrowser.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        filebrowser = {
          enable = true;

          openFirewall = !cfgNginx.enable;

          settings = {
            address = cfg.host;
            port = cfg.port;
            root = cfg.rootDir;
            database = "${cfg.rootDir}/database.db";
          };
        };

        fail2ban = {
          enable = true;

          jails.filebrowser.settings = {
            enabled = true;
            port = "80,443";
            protocol = "tcp";
            filter = "filebrowser";
            maxretry = 3;
            bantime = 3600; # 1 hour
            findtime = 600; # 10 minutes
            logpath = "/var/log/filebrowser.log";
            banaction = "iptables-allports";
            banaction_allports = "iptables-allports";
          };
        };
      };

      environment.etc."fail2ban/filter.d/filebrowser.conf".text = ''
        [INCLUDES]
        before = common.conf

        [Definition]
        datepattern = `^%%Y\/%%m\/%%d %%H:%%M:%%S`
        failregex   = `\/api\/login: 403 <HOST> *`
      '';
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

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              deny all;
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
