# Namecheap DNS API
# https://www.namecheap.com/support/api/intro/
# /etc/secrets/namecheap.env
# NAMECHEAP_API_USER=
# NAMECHEAP_API_KEY=
# NAMECHEAP_API_IP=
{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
  commonCertOptions = {
    dnsProvider = "namecheap";
    credentialsFile = "/etc/secrets/namecheap.env";
    webroot = null;
  };
in {
  options.services.acmectl = {
    enable = lib.mkEnableOption {
      description = "Enable ACME";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      acme = {
        acceptTerms = true;
        defaults.email = config.server.email;

        certs = lib.listToAttrs (map (domain: {
            name = domain;
            value = commonCertOptions;
          }) [
            config.server.domain
            "cockpit.${config.server.domain}"
            "nextcloud.${config.server.domain}"
            "immich.${config.server.domain}"
            "jellyfin.${config.server.domain}"
            "torrent.${config.server.domain}"
            "files.${config.server.domain}"
          ]);
      };
    };
  };
}
