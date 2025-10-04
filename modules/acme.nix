{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
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
        certs = {
          "${config.server.domain}" = {
            dnsProvider = "namecheap";
            credentialsFile = "/etc/secrets/namecheap.env";
            webroot = null;
          };
          "immich.${config.server.domain}" = {
            dnsProvider = "namecheap";
            credentialsFile = "/etc/secrets/namecheap.env";
            webroot = null;
          };
        };
      };
    };
  };
}
