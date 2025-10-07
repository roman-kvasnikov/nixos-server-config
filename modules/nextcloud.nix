# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloudctl;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    url = lib.mkOption {
      type = lib.types.str;
      description = "URL of the Nextcloud module";
      default = "https://nextcloud.${config.server.domain}";
    };

    adminpassFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for Nextcloud";
      default = "/etc/secrets/nextcloud-admin-pass";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nextcloud apps to enable";
      default = ["bookmarks" "calendar" "contacts" "tasks" "deck" "notes"];
    };
  };

  config = lib.mkIf cfg.enable {
    services.nextcloud = {
      enable = true;

      package = pkgs.nextcloud31;

      hostName = cfg.url;
      https = true;

      config = {
        adminpassFile = cfg.adminpassFile;
        dbtype = "sqlite";
      };

      extraAppsEnable = true;
      extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "${cfg.url}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
        };
      };
    };
  };
}
