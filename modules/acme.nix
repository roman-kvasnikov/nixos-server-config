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
        certs = {
          "${config.server.domain}" = {
            email = config.server.email;
            webroot = "/var/lib/acme/${config.server.domain}";
          };
          "immich.${config.server.domain}" = {
            email = config.server.email;
            webroot = "/var/lib/acme/immich.${config.server.domain}";
          };
        };
      };
    };
  };
}
