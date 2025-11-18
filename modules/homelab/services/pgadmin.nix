{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.pgadminctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.pgadminctl = {
    enable = lib.mkEnableOption "Enable PGAdmin";

    domain = lib.mkOption {
      description = "Domain of the PGAdmin module";
      type = lib.types.str;
      default = "pgadmin.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the PGAdmin module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the PGAdmin module";
      type = lib.types.port;
      default = 5050;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to PGAdmin";
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
        default = "PGAdmin";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "PostgreSQL management tool";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "pgadmin.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.pgadmin = {
        enable = true;

        port = cfg.port;

        openFirewall = !cfgNginx.enable;

        initialEmail = cfgHomelab.email;
        initialPasswordFile = config.age.secrets.pgadmin-password.path;
        minimumPasswordLength = 3;
      };

      age.secrets.pgadmin-password = {
        file = ../../../secrets/pgadmin.password.age;
        owner = "pgadmin";
        group = "pgadmin";
        mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.domain}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.domain}" = {
            enableACME = true;
            forceSSL = true;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) ''
              allow ${cfgHomelab.subnet};
              allow ${cfgHomelab.vpnSubnet};
              allow ${cfgHomelab.wireguardSubnet};
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
