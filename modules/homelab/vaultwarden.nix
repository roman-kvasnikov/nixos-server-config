{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.vaultwardenctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.vaultwardenctl = {
    enable = lib.mkEnableOption "Enable Vaultwarden";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Vaultwarden module";
      default = "vaultwarden.${cfgHomelab.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Vaultwarden";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Password manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "bitwarden.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.vaultwarden = {
        enable = true;

        config = {
          DOMAIN = "https://${cfg.host}";
          SIGNUPS_ALLOWED = true;
          ROCKET_LOG = "critical";
        };
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
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    })
  ];
}
