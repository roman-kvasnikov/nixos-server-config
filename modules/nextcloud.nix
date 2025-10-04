# https://mich-murphy.com/configure-nextcloud-nixos/
# https://nixos.wiki/wiki/Nextcloud
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloudctl;
  nextCloudApps = config.services.nextcloud.package.packages.apps;
in {
  options.services.nextcloudctl = {
    enable = lib.mkEnableOption {
      description = "Enable Nextcloud";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."nextcloud-admin-pass".text = "123";

    services.nextcloud = {
      enable = true;

      package = pkgs.nextcloud31;
      hostName = "nextcloud.${config.server.domain}";
      https = true;

      config = {
        adminpassFile = "/etc/nextcloud-admin-pass";
        dbtype = "sqlite";
      };

      extraAppsEnable = true;
      extraApps = {
        inherit (nextCloudApps) bookmarks calendar contacts tasks deck notes;
      };
    };

    services.nginx = lib.mkIf cfgNginx.enable {
      virtualHosts = {
        "nextcloud.${config.server.domain}" = {
          enableACME = cfgAcme.enable;
          forceSSL = cfgAcme.enable;
        };
      };
    };
  };
}
#   "bookmarks"
# , "calendar"
# , "contacts"
# , "deck"
# , "keeweb"
# , "mail"
# , "news"
# , "notes"
# , "onlyoffice"
# , "polls"
# , "tasks"
# , "twofactor_webauthn"

