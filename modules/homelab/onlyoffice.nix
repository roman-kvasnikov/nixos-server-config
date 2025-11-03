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

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Only Office module";
      default = "onlyoffice.${cfgHomelab.domain}";
    };

    allowExternal = lib.mkOption {
      type = lib.types.bool;
      description = "Allow external access to Only Office.";
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

        hostname = cfg.host;

        jwtSecretFile = cfg.jwtSecretFile;
      };
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx = {
        virtualHosts = {
          "${cfg.host}" = {
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
