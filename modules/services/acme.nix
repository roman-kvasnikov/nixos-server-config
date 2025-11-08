{
  config,
  lib,
  ...
}: let
  cfg = config.services.acmectl;
  cfgHomelab = config.homelab;
in {
  options.services.acmectl = {
    enable = lib.mkEnableOption "Enable ACME";

    commonCertOptions = lib.mkOption {
      type = lib.types.attrs;
      description = "Common options for ACME certificates";
      default = {
        dnsProvider = "namecheap";
        credentialsFile = config.age.secrets.namecheap-env.path;
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
        defaults.email = cfgHomelab.email;
      };
    };

    age.secrets.namecheap-env = {
      file = ../../secrets/namecheap.env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
