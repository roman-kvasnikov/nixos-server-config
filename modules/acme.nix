{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
  cfgServer = config.server;
  cfgServices = config.services;
in {
  options.services.acmectl = {
    enable = lib.mkEnableOption "Enable ACME";

    commonCertOptions = lib.mkOption {
      type = lib.types.attrs;
      description = "Common options for ACME certificates";
      default = {
        dnsProvider = "namecheap";
        credentialsFile = "/etc/secrets/namecheap.env";
        webroot = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      acme = {
        acceptTerms = true;
        defaults.email = cfgServer.email;

        certs = lib.listToAttrs (map (domain: {
            name = domain;
            value = cfg.commonCertOptions;
          }) [
            cfgServer.domain
            cfgServices.cockpitctl.host
            cfgServices.delugectl.host
            # cfgServices.filebrowserctl.host
            cfgServices.immichctl.host
            cfgServices.jellyfinctl.host
            cfgServices.nextcloudctl.host
            # cfgServices.qbittorrentctl.host
            # cfgServices.unifictl.host
            cfgServices.uptime-kumactl.host
          ]);
      };
    };
  };
}
