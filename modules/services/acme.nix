{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
  cfgServer = config.server;
in {
  options.services.acmectl = {
    enable = lib.mkEnableOption "Enable ACME";

    commonCertOptions = lib.mkOption {
      type = lib.types.attrs;
      description = "Common options for ACME certificates";
      default = {
        dnsProvider = "namecheap";
        credentialsFile = config.age.secrets.acme-namecheap-env.path;
        webroot = null;
        postRun = ''
          systemctl reload nginx
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      acme = {
        acceptTerms = true;
        defaults.email = cfgServer.email;
      };
    };
  };
}
