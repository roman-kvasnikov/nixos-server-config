{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
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
    environment.etc = {
      ${cfg.commonCertOptions.credentialsFile}.text = ''
        NAMECHEAP_API_USER=RomanKW
        NAMECHEAP_API_KEY=545cef3f919847b28999ca3eb2b643b9
        NAMECHEAP_API_IP=188.243.2.115
      '';
    };

    security = {
      acme = {
        acceptTerms = true;
        defaults.email = config.server.email;

        certs = lib.listToAttrs (map (domain: {
            name = domain;
            value = cfg.commonCertOptions;
          }) [
            config.server.domain
            "cockpit.${config.server.domain}"
            "nextcloud.${config.server.domain}"
            "immich.${config.server.domain}"
            "jellyfin.${config.server.domain}"
            "torrent.${config.server.domain}"
            # "files.${config.server.domain}"
            # "unifi.${config.server.domain}"
          ]);
      };
    };
  };
}
