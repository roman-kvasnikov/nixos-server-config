# TODO: проработать dataDir для ваультварден:
# https://github.com/NixOS/nixpkgs/blob/d916df777523d75f7c5acca79946652f032f633e/nixos/modules/services/security/vaultwarden/default.nix #L282
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
      default = "passwords.${cfgHomelab.domain}";
    };

    backupDir = lib.mkOption {
      type = lib.types.path;
      description = "Backup directory for Vaultwarden";
      default = "/data/vaultwarden";
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

        dbBackend = "postgresql";

        backupDir = cfg.backupDir;

        config = {
          DOMAIN = "https://${cfg.host}";
          SIGNUPS_ALLOWED = true;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";

          # This example assumes a mailserver running on localhost,
          # thus without transport encryption.
          # If you use an external mail server, follow:
          #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
          # SMTP_HOST = "127.0.0.1";
          # SMTP_PORT = 25;
          # SMTP_SSL = false;
          # SMTP_FROM = "admin@bitwarden.example.com";
          # SMTP_FROM_NAME = "example.com Bitwarden server";
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
