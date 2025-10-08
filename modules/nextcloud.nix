# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloudctl;
  cfgServer = config.server;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Nextcloud module";
      default = "nextcloud.${cfgServer.domain}";
    };

    adminpassFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for Nextcloud";
      default = "/etc/secrets/nextcloud/nextcloud-admin-pass";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nextcloud apps to enable";
      default = ["bookmarks" "calendar" "contacts" "tasks" "notes" "mail"];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.nextcloud = {
        enable = true;

        package = pkgs.nextcloud31;

        hostName = cfg.host;
        https = true;

        database.createLocally = true;
        configureRedis = true;
        maxUploadSize = "16G";

        extraAppsEnable = true;
        autoUpdateApps.enable = true;
        extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});

        config = {
          dbtype = "sqlite";
          adminpassFile = cfg.adminpassFile;
          overwriteProtocol = "https";
          defaultPhoneRegion = "RU";
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
          };
        };
      };
    })
  ];
}
