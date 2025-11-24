{
  config,
  lib,
  pkgs,
  cfgHomelab,
  cfgAcme,
  cfgNginx,
  denyExternal,
  ...
}: let
  cfg = config.homelab.services.onlyofficectl;
in {
  options.homelab.services.onlyofficectl = {
    enable = lib.mkEnableOption "Enable Only Office";

    domain = lib.mkOption {
      description = "Domain of the Only Office module";
      type = lib.types.str;
      default = "onlyoffice.${cfgHomelab.domain}";
    };

    host = lib.mkOption {
      description = "Host of the Only Office module";
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      description = "Port of the Only Office module";
      type = lib.types.port;
      default = 8000;
    };

    allowExternal = lib.mkOption {
      description = "Allow external access to Only Office";
      type = lib.types.bool;
      default = true;
    };

    jwtSecretFile = lib.mkOption {
      description = "JWT Secret file for Only Office";
      type = lib.types.path;
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

      age.secrets.onlyoffice-jwt-secret = {
        file = ../../../secrets/onlyoffice.jwt-secret.age;
        owner = "onlyoffice";
        group = "onlyoffice";
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
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;
            http2 = true;

            extraConfig = lib.mkIf (!cfg.allowExternal) denyExternal;
          };
        };
      };
    })
  ];
}
