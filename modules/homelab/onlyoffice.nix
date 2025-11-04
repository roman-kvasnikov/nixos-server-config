{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.onlyofficectl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.onlyofficectl = {
    enable = lib.mkEnableOption "Enable Only Office";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of the Only Office module";
      default = "onlyoffice.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Only Office module";
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port of the Only Office module";
      default = 8000;
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Only Office";
      default = true;
    };

    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = "JWT Secret file for Only Office";
      default = config.age.secrets.onlyoffice-jwt-secret.path;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.onlyoffice = {
        enable = true;

        hostname = cfg.domain;
        port = cfg.port;

        jwtSecretFile = cfg.jwtSecretFile;
      };
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
          };
        };
      };
    })
  ];
}
