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
            webroot = "/var/lib/acme/${config.server.domain}";
          };
          "immich.${config.server.domain}" = {
            webroot = "/var/lib/acme/immich.${config.server.domain}";
          };
        };
      };
    };
  };
}
