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
      hostName = "192.168.1.11";
      config.adminpassFile = "/etc/nextcloud-admin-pass";
      config.dbtype = "sqlite";

      extraAppsEnable = true;
      extraApps = {
        inherit (nextCloudApps) bookmarks calendar contacts tasks deck notes;
      };
    };
    networking.firewall.allowedTCPPorts = [80 443];
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

